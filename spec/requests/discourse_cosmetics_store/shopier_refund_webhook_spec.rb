# frozen_string_literal: true

RSpec.describe "Shopier refund webhook" do
  let(:webhook_token) { "shopier-refund-webhook-token" }
  let(:user) { Fabricate(:user) }
  let(:orb_package) do
    DiscourseCosmeticsStore::OrbPackage.create!(
      name: "100 Orbs",
      orb_amount: 100,
      price_minor: 4_990,
      currency: "TRY",
      provider_config: {
        "providers" => ["shopier"],
        "shopier_product_id" => "50193950",
        "shopier_checkout_url" => "https://www.shopier.com/example/50193950",
      },
    )
  end
  let(:payment) do
    DiscourseCosmeticsStore::Payment.create!(
      token: SecureRandom.hex(24),
      user: user,
      orb_package: orb_package,
      provider: "shopier",
      status: "completed",
      orb_amount: 100,
      amount_minor: 4_990,
      currency: "TRY",
      provider_payment_id: "SHOPIER-ORDER-42",
      completed_at: Time.zone.now,
    )
  end

  before do
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_payments_enabled = true
    SiteSetting.discourse_cosmetics_store_shopier_enabled = true
    SiteSetting.discourse_cosmetics_store_shopier_webhook_token = webhook_token
    DiscourseCosmeticsStore::WalletService.credit!(
      user: user,
      amount: payment.orb_amount,
      entry_type: "payment",
      idempotency_key: "payment:#{payment.id}",
      reason: "#{orb_package.name} satın alımı",
      reference_type: "DiscourseCosmeticsStore::Payment",
      reference_id: payment.id,
    )
  end

  def post_shopier(payload, event: nil, webhook_id:, signature: nil)
    raw = JSON.generate(payload)
    signature ||= OpenSSL::HMAC.hexdigest("SHA256", webhook_token, raw)
    headers = {
      "CONTENT_TYPE" => "application/json",
      "Shopier-Signature" => signature,
      "Shopier-Webhook-Id" => webhook_id,
    }
    headers["Shopier-Event"] = event if event
    post "/cosmetics-store/webhooks/shopier",
         params: raw,
         headers: headers
  end

  def refund_payload(status: nil, amount: "49.90")
    payload = {
      "id" => "SHOPIER-REFUND-9",
      "type" => amount == "49.90" ? "full" : "partial",
      "orderId" => payment.provider_payment_id,
      "currency" => "TRY",
      "total" => amount,
    }
    payload["status"] = status if status
    payload
  end

  it "reverses a completed full refund exactly once" do
    payload = refund_payload(status: "succeeded")
    SiteSetting.discourse_cosmetics_store_payments_enabled = false

    post_shopier(payload, webhook_id: "EVENT-1")

    expect(response.status).to eq(200)
    expect(payment.reload.status).to eq("refunded")
    expect(payment.refunded_amount_minor).to eq(4_990)
    expect(payment.refunded_orb_amount).to eq(100)
    wallet = DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id)
    expect(wallet.balance).to eq(0)
    expect(wallet.debt).to eq(0)
    expect(DiscourseCosmeticsStore::PaymentRefund.count).to eq(1)

    post_shopier(payload, webhook_id: "EVENT-1")

    expect(response.status).to eq(200)
    expect(DiscourseCosmeticsStore::PaymentRefund.count).to eq(1)
    expect(
      DiscourseCosmeticsStore::LedgerEntry.where(entry_type: "refund").count,
    ).to eq(1)
  end

  it "tracks requested refunds and only reverses them after success" do
    post_shopier(
      refund_payload(status: "pending"),
      event: "refund.requested",
      webhook_id: "EVENT-REQUESTED",
    )

    expect(response.status).to eq(200)
    expect(payment.reload.status).to eq("completed")
    expect(DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id).balance).to eq(100)
    expect(DiscourseCosmeticsStore::PaymentRefund.last.status).to eq("requested")

    post_shopier(
      refund_payload(status: "succeeded"),
      event: "refund.updated",
      webhook_id: "EVENT-SUCCEEDED",
    )

    expect(response.status).to eq(200)
    expect(payment.reload.status).to eq("refunded")
    expect(DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id).balance).to eq(0)
    expect(DiscourseCosmeticsStore::PaymentRefund.count).to eq(1)
  end

  it "records debt when refunded Orbs have already been spent" do
    DiscourseCosmeticsStore::WalletService.debit!(
      user: user,
      amount: 80,
      entry_type: "purchase",
      idempotency_key: "purchase:test:#{user.id}",
      reason: "Test kozmetik satın alımı",
    )

    post_shopier(
      refund_payload(status: "succeeded"),
      event: "refund.updated",
      webhook_id: "EVENT-DEBT",
    )

    wallet = DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id)
    expect(response.status).to eq(200)
    expect(wallet.balance).to eq(0)
    expect(wallet.debt).to eq(80)

    DiscourseCosmeticsStore::WalletService.credit!(
      user: user,
      amount: 50,
      entry_type: "mission_reward",
      idempotency_key: "mission:test:#{user.id}",
      reason: "Test görevi",
    )

    expect(wallet.reload.balance).to eq(0)
    expect(wallet.debt).to eq(30)
  end

  it "rejects a refund with an invalid signature" do
    post_shopier(
      refund_payload(status: "succeeded"),
      event: "refund.updated",
      webhook_id: "EVENT-BAD",
      signature: "0" * 64,
    )

    expect(response.status).to eq(401)
    expect(payment.reload.status).to eq("completed")
    expect(DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id).balance).to eq(100)
  end
end
