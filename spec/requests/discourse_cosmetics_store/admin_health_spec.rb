# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::AdminController do
  fab!(:admin)

  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_payments_enabled = false
    sign_in(admin)
  end

  it "includes the read-only health summary in the existing admin catalog payload" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Health item")
    product =
      DiscourseCosmeticsStore::Product.create!(
        name: "Health product",
        product_type: "item",
        price: 25,
        exclusive: true,
      )
    DiscourseCosmeticsStore::ProductItem.create!(product: product, cosmetic_item: item, position: 0)

    get "/admin/plugins/user-cosmetics-store/catalog.json"

    expect(response.status).to eq(200)
    health = response.parsed_body.fetch("health")
    expect(health.fetch("status")).to eq("healthy")
    expect(health.fetch("checks").map { |row| row.fetch("id") }).to include(
      "base_plugin",
      "integration",
      "preview_contract",
      "loadout_contract",
      "empty_products",
      "disabled_cosmetic_items",
      "invalid_availability",
      "payment_providers",
    )
    expect(health.to_json).not_to include("secret", "password", "api_key", "merchant_key")
  end
end
