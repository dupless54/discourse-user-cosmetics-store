# frozen_string_literal: true

RSpec.describe "Shopier OSB callback" do
  let(:username) { "osb-user" }
  let(:password) { "osb-password" }
  let(:payload) do
    {
      "email" => "test@example.com",
      "orderid" => "TEST-ORDER",
      "currency" => 0,
      "price" => "1.00",
      "productid" => 123,
      "istest" => 1,
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
    SiteSetting.discourse_cosmetics_store_payments_enabled = false
  end

  it "acknowledges a verified test notification without enabling live payments" do
    post "/cosmetics-store/callbacks/shopier-osb", params: { res: encoded_result, hash: signature }

    expect(response.status).to eq(200)
    expect(response.body).to eq("success")
  end

  it "rejects a test notification with an invalid digest" do
    post "/cosmetics-store/callbacks/shopier-osb",
         params: {
           res: encoded_result,
           hash: "0" * 64,
         }

    expect(response.status).to eq(401)
  end
end
