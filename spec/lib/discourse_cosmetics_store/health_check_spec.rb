# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::HealthCheck do
  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_payments_enabled = false
  end

  def check(result, id)
    result.fetch(:checks).find { |row| row[:id] == id }
  end

  def product_with_item!(name:)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "#{name} item")
    product =
      DiscourseCosmeticsStore::Product.create!(
        name: name,
        product_type: "item",
        price: 25,
        exclusive: true,
      )
    DiscourseCosmeticsStore::ProductItem.create!(product: product, cosmetic_item: item, position: 0)
    [product, item]
  end

  it "reports the Base contracts and a clean catalog without exposing credentials" do
    product_with_item!(name: "Healthy product")

    result = described_class.call

    expect(result[:status]).to eq("healthy")
    expect(check(result, "base_plugin")[:status]).to eq("ok")
    expect(check(result, "integration")[:status]).to eq("ok")
    expect(check(result, "preview_contract")[:status]).to eq("ok")
    expect(check(result, "loadout_contract")[:status]).to eq("ok")
    expect(check(result, "empty_products")[:value]).to eq(0)
    expect(check(result, "disabled_cosmetic_items")[:value]).to eq(0)
    expect(check(result, "invalid_availability")[:value]).to eq(0)
    expect(check(result, "payment_providers").keys).to contain_exactly(
      :id,
      :status,
      :value,
      :total,
      :payments_enabled,
    )
  end

  it "warns about catalog integrity problems without mutating them" do
    product, item = product_with_item!(name: "Broken product")
    item.update!(enabled: false)
    empty_product =
      DiscourseCosmeticsStore::Product.create!(
        name: "Empty product",
        product_type: "item",
        price: 10,
        exclusive: true,
      )
    product.update_columns(
      available_from: 2.days.from_now,
      available_until: 1.day.from_now,
    )

    result = described_class.call

    expect(result[:status]).to eq("warning")
    expect(check(result, "disabled_cosmetic_items")).to include(status: "warning", value: 1)
    expect(check(result, "empty_products")).to include(status: "warning", value: 1)
    expect(check(result, "invalid_availability")).to include(status: "warning", value: 1)
    expect(item.reload.enabled).to eq(false)
    expect(empty_product.reload.enabled).to eq(true)
  end
end
