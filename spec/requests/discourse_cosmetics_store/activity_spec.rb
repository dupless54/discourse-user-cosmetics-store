# frozen_string_literal: true

RSpec.describe "Cosmetics Store activity" do
  fab!(:user)
  fab!(:recipient) { Fabricate(:user) }
  fab!(:sender) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  before do
    enable_current_plugin
    SiteSetting.discourse_cosmetics_store_starting_balance = 1_000
  end

  it "returns an empty private-safe payload to anonymous visitors" do
    get "/cosmetics-store/activity.json"

    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("private")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body.dig("viewer", "logged_in")).to eq(false)
    expect(response.parsed_body.dig("activity", "events")).to eq([])
    expect(response.parsed_body.dig("activity", "wallet", "balance")).to eq(0)
  end

  it "shows only the current user's purchases, gifts, and non-duplicate Orb activity" do
    purchase_product = create_product("Bought Frame", 120)
    sent_product = create_product("Gifted Plate", 80)
    received_product = create_product("Received Effect", 70)
    private_product = create_product("Other User Secret", 50)

    DiscourseCosmeticsStore::Purchase.create!(
      user: user,
      product: purchase_product,
      price_paid: 120,
      status: "completed",
      idempotency_key: "purchase:activity:#{user.id}",
    )
    DiscourseCosmeticsStore::Gift.create!(
      sender: user,
      recipient: recipient,
      product: sent_product,
      price_paid: 80,
      status: "completed",
      idempotency_key: "gift:sent:activity:#{user.id}",
    )
    DiscourseCosmeticsStore::Gift.create!(
      sender: sender,
      recipient: user,
      product: received_product,
      price_paid: 70,
      status: "completed",
      idempotency_key: "gift:received:activity:#{user.id}",
    )
    DiscourseCosmeticsStore::Purchase.create!(
      user: other_user,
      product: private_product,
      price_paid: 50,
      status: "completed",
      idempotency_key: "purchase:activity:#{other_user.id}",
    )

    DiscourseCosmeticsStore::WalletService.debit!(
      user: user,
      amount: 120,
      entry_type: "purchase",
      idempotency_key: "ledger:purchase:activity:#{user.id}",
      reason: "private purchase audit reason",
    )
    DiscourseCosmeticsStore::WalletService.debit!(
      user: user,
      amount: 80,
      entry_type: "gift",
      idempotency_key: "ledger:gift:activity:#{user.id}",
      reason: "private gift audit reason",
    )
    DiscourseCosmeticsStore::WalletService.credit!(
      user: user,
      amount: 25,
      entry_type: "mission_reward",
      idempotency_key: "ledger:mission:activity:#{user.id}",
      reason: "private mission audit reason",
    )
    DiscourseCosmeticsStore::WalletService.credit!(
      user: other_user,
      amount: 99,
      entry_type: "mission_reward",
      idempotency_key: "ledger:mission:activity:#{other_user.id}",
      reason: "other user's private reason",
    )

    sign_in(user)
    get "/cosmetics-store/activity.json"

    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("private")
    expect(response.headers["Cache-Control"]).to include("no-store")

    payload = response.parsed_body
    events = payload.dig("activity", "events")
    kinds = events.map { |event| event["kind"] }

    expect(kinds).to include("purchase", "gift_sent", "gift_received", "orb")
    expect(events.select { |event| event["kind"] == "orb" }.map { |event| event["entry_type"] }).to contain_exactly(
      "starting_balance",
      "mission_reward",
    )

    purchase = events.find { |event| event["kind"] == "purchase" }
    sent_gift = events.find { |event| event["kind"] == "gift_sent" }
    received_gift = events.find { |event| event["kind"] == "gift_received" }

    expect(purchase.dig("product", "name")).to eq("Bought Frame")
    expect(purchase["amount"]).to eq(-120)
    expect(sent_gift.dig("counterparty", "username")).to eq(recipient.username)
    expect(sent_gift["amount"]).to eq(-80)
    expect(received_gift.dig("counterparty", "username")).to eq(sender.username)
    expect(received_gift).not_to have_key("amount")

    expect(payload.dig("activity", "stats")).to include(
      "purchases" => 1,
      "gifts_sent" => 1,
      "gifts_received" => 1,
      "orb_events" => 2,
    )
    expect(payload.dig("activity", "wallet")).to include(
      "balance" => 825,
      "debt" => 0,
      "lifetime_earned" => 1_025,
      "lifetime_spent" => 200,
    )

    serialized = response.body
    expect(serialized).not_to include("Other User Secret")
    expect(serialized).not_to include("other user's private reason")
    expect(serialized).not_to include("private purchase audit reason")
    expect(serialized).not_to include("idempotency_key")
  end

  def create_product(name, price)
    DiscourseCosmeticsStore::Product.create!(
      name: name,
      product_type: "item",
      price: price,
      enabled: true,
      exclusive: true,
    )
  end
end
