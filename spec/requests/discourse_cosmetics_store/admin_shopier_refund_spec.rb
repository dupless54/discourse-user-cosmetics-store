# frozen_string_literal: true

RSpec.describe "Admin Shopier refund reconciliation" do
  let(:admin) { Fabricate(:admin) }
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
      provider_payment_id: "SHOPIER-ORDER-77",
      completed_at: Time.zone.now,
    )
  end

  before do
    sign_in(admin)
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

  it "records a partial completed refund without sending a provider request" do
    post "/admin/plugins/user-cosmetics-store/payments/#{payment.token}/refund.json",
         params: {
           amount: "24.95",
           refund_reference: "SHOPIER-MANUAL-REFUND-1",
           reason: "Müşteri talebi",
         }

    expect(response.status).to eq(200)
    expect(payment.reload.status).to eq("partially_refunded")
    expect(payment.refunded_amount_minor).to eq(2_495)
    expect(payment.refunded_orb_amount).to eq(50)
    expect(DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id).balance).to eq(50)
    expect(DiscourseCosmeticsStore::PaymentRefund.last.source).to eq("manual")

    post "/admin/plugins/user-cosmetics-store/payments/#{payment.token}/refund.json",
         params: {
           amount: "24.95",
           refund_reference: "SHOPIER-MANUAL-REFUND-1",
           reason: "Müşteri talebi",
         }

    expect(response.status).to eq(200)
    expect(payment.reload.refunded_amount_minor).to eq(2_495)
    expect(DiscourseCosmeticsStore::PaymentRefund.count).to eq(1)

    post "/admin/plugins/user-cosmetics-store/payments/#{payment.token}/refund.json",
         params: {
           amount: "24.95",
           refund_reference: "SHOPIER-MANUAL-REFUND-2",
           reason: "Kalan tutar",
         }

    expect(response.status).to eq(200)
    expect(payment.reload.status).to eq("refunded")
    expect(payment.refunded_orb_amount).to eq(100)
    expect(DiscourseCosmeticsStore::Wallet.find_by!(user_id: user.id).balance).to eq(0)
  end
end
