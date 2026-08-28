# frozen_string_literal: true

RSpec.describe "Cosmetics Store history" do
  fab!(:user)
  fab!(:recipient, :user)
  fab!(:sender, :user)
  fab!(:other_user, :user)

  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
  end

  it "does not expose personal history to anonymous visitors" do
    product = create_product("Anonymous secret")
    create_purchase(user: user, product: product, key: "purchase:anon")

    get "/cosmetics-store/history.json"

    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body.dig("viewer", "logged_in")).to eq(false)
    expect(response.parsed_body.dig("history", "purchases")).to eq([])
    expect(response.parsed_body.dig("history", "gifts_sent")).to eq([])
    expect(response.parsed_body.dig("history", "gifts_received")).to eq([])
  end

  it "returns only the signed-in user's purchases and gifts" do
    purchased_product = create_product("Purchased frame")
    sent_product = create_product("Sent nameplate")
    received_product = create_product("Received card")
    unrelated_product = create_product("Someone else's product")

    create_purchase(user: user, product: purchased_product, key: "purchase:self", price: 125)
    create_purchase(user: other_user, product: unrelated_product, key: "purchase:other", price: 999)

    create_gift(
      sender: user,
      recipient: recipient,
      product: sent_product,
      key: "gift:sent",
      price: 250,
    )
    create_gift(
      sender: sender,
      recipient: user,
      product: received_product,
      key: "gift:received",
      price: 375,
    )
    create_gift(
      sender: sender,
      recipient: other_user,
      product: unrelated_product,
      key: "gift:other",
      price: 500,
    )

    sign_in(user)
    get "/cosmetics-store/history.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body

    expect(payload.dig("viewer", "logged_in")).to eq(true)
    expect(payload.dig("history", "stats")).to include(
      "purchase_count" => 1,
      "gifts_sent_count" => 1,
      "gifts_received_count" => 1,
    )

    purchase = payload.dig("history", "purchases").sole
    expect(purchase.dig("product", "name")).to eq("Purchased frame")
    expect(purchase["price_paid"]).to eq(125)

    sent = payload.dig("history", "gifts_sent").sole
    expect(sent.dig("product", "name")).to eq("Sent nameplate")
    expect(sent.dig("user", "username")).to eq(recipient.username)
    expect(sent.dig("user", "path")).to eq("/u/#{recipient.username_lower}")

    received = payload.dig("history", "gifts_received").sole
    expect(received.dig("product", "name")).to eq("Received card")
    expect(received.dig("user", "username")).to eq(sender.username)

    serialized_names =
      payload
        .dig("history")
        .values_at("purchases", "gifts_sent", "gifts_received")
        .flatten
        .filter_map { |row| row.dig("product", "name") }
    expect(serialized_names).not_to include("Someone else's product")
  end

  it "keeps refunded records visible with their historical paid price" do
    product = create_product("Refunded frame")
    purchase = create_purchase(user: user, product: product, key: "purchase:refunded", price: 420)
    purchase.update!(status: "refunded")

    sign_in(user)
    get "/cosmetics-store/history.json"

    record = response.parsed_body.dig("history", "purchases").sole
    expect(record["status"]).to eq("refunded")
    expect(record["price_paid"]).to eq(420)
  end

  def create_product(name)
    DiscourseCosmeticsStore::Product.create!(
      name: name,
      product_type: "item",
      price: 100,
      enabled: true,
      exclusive: true,
    )
  end

  def create_purchase(user:, product:, key:, price: 100)
    DiscourseCosmeticsStore::Purchase.create!(
      user: user,
      product: product,
      price_paid: price,
      status: "completed",
      idempotency_key: key,
    )
  end

  def create_gift(sender:, recipient:, product:, key:, price: 100)
    DiscourseCosmeticsStore::Gift.create!(
      sender: sender,
      recipient: recipient,
      product: product,
      price_paid: price,
      status: "completed",
      idempotency_key: key,
    )
  end
end
