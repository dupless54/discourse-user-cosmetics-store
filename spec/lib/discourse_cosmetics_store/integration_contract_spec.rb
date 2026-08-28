# frozen_string_literal: true

RSpec.describe "Cosmetics Store integration contract" do
  fab!(:user)
  fab!(:recipient) { Fabricate(:user, active: true) }

  before do
    skip "base Integration API is not installed in this test job" unless DiscourseCosmeticsStore.base_integration_ready?

    enable_current_plugin
    SiteSetting.discourse_cosmetics_store_starting_balance = 500
    DiscourseCosmeticsStore.install_cosmetics_integration!
    DiscourseCosmeticsStore::Catalog.bump!
  end

  after do
    DiscourseCosmeticsStore::Catalog.bump! if defined?(DiscourseCosmeticsStore::Catalog)
  end

  it "locks an exclusive public cosmetic until the user directly owns it" do
    item = create_item("Exclusive frame")
    create_product(item: item, exclusive: true)

    expect(entitled?(user, item)).to eq(false)

    DiscourseUserCosmetics::Integration.grant!(user: user, item: item)

    expect(entitled?(user, item)).to eq(true)
  end

  it "keeps group access for an exclusive cosmetic" do
    group = Fabricate(:group)
    item = create_item("Group frame")
    item.item_groups.create!(group: group)
    create_product(item: item, exclusive: true)
    GroupUser.create!(group: group, user: user)

    expect(entitled?(user, item)).to eq(true)
  end

  it "abstains for non-exclusive cosmetics so base public access remains authoritative" do
    item = create_item("Public frame")
    create_product(item: item, exclusive: false)

    expect(entitled?(user, item)).to eq(true)
  end

  it "grants purchased exclusive cosmetics through the base integration contract" do
    item = create_item("Purchased frame")
    product = create_product(item: item, exclusive: true, price: 125)

    service = DiscourseCosmeticsStore::PurchaseService.new(user: user, product: product).call

    expect(service.purchase.status).to eq("completed")
    expect(DiscourseUserCosmetics::Integration.owns?(user: user, item: item)).to eq(true)
    expect(service.wallet.balance).to eq(375)
  end

  it "grants gifted exclusive cosmetics through the base integration contract" do
    item = create_item("Gift frame")
    product = create_product(item: item, exclusive: true, price: 100)

    service =
      DiscourseCosmeticsStore::GiftService.new(
        sender: user,
        product: product,
        recipient_username: recipient.username,
      ).call

    expect(service.gift.status).to eq("completed")
    expect(DiscourseUserCosmetics::Integration.owns?(user: recipient, item: item)).to eq(true)
    expect(service.wallet.balance).to eq(400)
  end

  def create_item(name)
    DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: name, enabled: true)
  end

  def create_product(item:, exclusive:, price: 100)
    product =
      DiscourseCosmeticsStore::Product.create!(
        name: "Store #{item.name}",
        product_type: "item",
        price: price,
        enabled: true,
        exclusive: exclusive,
      )
    DiscourseCosmeticsStore::ProductItem.create!(product: product, cosmetic_item: item, position: 0)
    DiscourseCosmeticsStore::Catalog.bump!
    product
  end

  def entitled?(candidate, item)
    DiscourseUserCosmetics::Integration
      .entitled_item_ids(user: candidate, items: [item])
      .key?(item.id)
  end
end
