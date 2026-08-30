# frozen_string_literal: true

RSpec.describe "Discourse Cosmetics Store server i18n" do
  fab!(:user)
  fab!(:admin)

  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_starting_balance = 100
  end

  def create_limited_product!
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Localized frame")
    product = DiscourseCosmeticsStore::Product.create!(
      name: "Localized product",
      product_type: "item",
      price: 25,
      exclusive: true,
      available_until: 1.day.from_now,
    )
    DiscourseCosmeticsStore::ProductItem.create!(
      product: product,
      cosmetic_item: item,
      position: 0,
    )
    [product, item]
  end

  it "uses the active server locale for storefront-generated labels" do
    product, = create_limited_product!

    get "/cosmetics-store.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    serialized_product = payload.fetch("products").find { |row| row.fetch("id") == product.id }

    expect(serialized_product.dig("items", 0, "kind_label")).to eq("Avatar frame")
    expect(
      payload.fetch("filters").fetch("availability").find { |row| row.fetch("value") == "limited" }.fetch("label"),
    ).to eq("Limited time")
    expect(payload.dig("viewer", "preview_user", "name")).to eq("Community member")
    expect(payload.dig("viewer", "preview_user", "username")).to eq("user")
  end

  it "uses the active server locale for admin metrics and validation errors" do
    sign_in(admin)

    get "/admin/plugins/user-cosmetics-store/catalog.json"

    expect(response.status).to eq(200)
    metric = response.parsed_body.fetch("mission_metrics").find { |row| row.fetch("value") == "posts_created" }
    expect(metric.fetch("label")).to eq("Posts created")

    post "/admin/plugins/user-cosmetics-store/products.json",
         params: {
           product: {
             name: "Invalid localized product",
             product_type: "item",
             price: 25,
             enabled: true,
             exclusive: true,
             cosmetic_item_ids: [],
           },
         }

    expect(response.status).to eq(422)
    expect(response.parsed_body.fetch("errors")).to include(
      "A single product must contain exactly one cosmetic.",
    )
  end
end
