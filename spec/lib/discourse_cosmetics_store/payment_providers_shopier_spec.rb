# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::PaymentProviders::Shopier do
  let(:username) { "osb-user" }
  let(:password) { "osb-password" }
  let(:payload) do
    {
      "email" => "member@example.com",
      "orderid" => "ORDER-42",
      "currency" => 0,
      "price" => "49.90",
      "productid" => 123_456,
      "istest" => 0,
    }
  end
  let(:encoded_result) { Base64.strict_encode64(JSON.generate(payload)) }
  let(:signature) do
    OpenSSL::HMAC.hexdigest("SHA256", password, "#{encoded_result}#{username}")
  end

  before do
    SiteSetting.discourse_cosmetics_store_shopier_enabled = true
    SiteSetting.discourse_cosmetics_store_shopier_osb_username = username
    SiteSetting.discourse_cosmetics_store_shopier_osb_password = password
    SiteSetting.discourse_cosmetics_store_shopier_webhook_token = ""
  end

  it "verifies and decodes a signed OSB result" do
    expect(described_class.verify_osb!(encoded_result, signature)).to eq(payload)
  end

  it "rejects an invalid OSB digest" do
    expect do
      described_class.verify_osb!(encoded_result, "0" * 64)
    end.to raise_error(
      DiscourseCosmeticsStore::PaymentProviders::VerificationError,
      "Shopier OSB özeti geçersiz",
    )
  end

  it "configures Shopier using OSB credentials without a modern webhook token" do
    expect(described_class.configured?).to eq(true)
  end

  it "normalizes Shopier OSB currency codes" do
    expect(described_class.osb_currency(0)).to eq("TRY")
    expect(described_class.osb_currency("1")).to eq("USD")
    expect(described_class.osb_currency(2)).to eq("EUR")
  end

  it "recognizes test notifications" do
    expect(described_class.osb_test?(payload.merge("istest" => 1))).to eq(true)
    expect(described_class.osb_test?(payload)).to eq(false)
  end
end
