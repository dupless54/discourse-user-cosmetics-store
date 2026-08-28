# frozen_string_literal: true

RSpec.describe "Cosmetics Store inventory" do
  fab!(:user)

  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
    DiscourseCosmeticsStore::Catalog.bump!
  end

  after do
    DiscourseCosmeticsStore::Catalog.bump! if defined?(DiscourseCosmeticsStore::Catalog)
  end

  it "does not expose personal inventory to anonymous visitors" do
    get "/cosmetics-store/inventory.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("viewer", "logged_in")).to eq(false)
    expect(response.parsed_body.dig("inventory", "items")).to eq([])
    expect(response.parsed_body["collections"]).to eq([])
  end

  it "separates direct ownership from current access and reports collection progress" do
    directly_owned = create_item("Owned frame")
    group_unlocked = create_item("Group frame")
    group = Fabricate(:group)
    group_unlocked.item_groups.create!(group: group)
    GroupUser.create!(group: group, user: user)

    create_collection_product(directly_owned, "night-set")
    create_collection_product(group_unlocked, "night-set")
    DiscourseUserCosmetics::UserItem.create!(user_id: user.id, item_id: directly_owned.id)
    DiscourseCosmeticsStore::Catalog.bump!

    sign_in(user)
    get "/cosmetics-store/inventory.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    items = payload.dig("inventory", "items").index_by { |item| item["id"] }

    expect(items.dig(directly_owned.id, "directly_owned")).to eq(true)
    expect(items.dig(directly_owned.id, "unlocked")).to eq(true)
    expect(items.dig(group_unlocked.id, "directly_owned")).to eq(false)
    expect(items.dig(group_unlocked.id, "unlocked")).to eq(true)

    collection = payload["collections"].find { |row| row["slug"] == "night-set" }
    expect(collection["item_count"]).to eq(2)
    expect(collection["directly_owned_item_count"]).to eq(1)
    expect(collection["unlocked_item_count"]).to eq(2)
    expect(collection["directly_owned_percent"]).to eq(50)
    expect(collection["unlocked_percent"]).to eq(100)
    expect(collection["directly_owned_complete"]).to eq(false)
    expect(collection["unlocked_complete"]).to eq(true)
  end

  it "returns collection progress without building the full inventory for collection scope" do
    item = create_item("Collection frame")
    create_collection_product(item, "scope-set")
    DiscourseUserCosmetics::UserItem.create!(user_id: user.id, item_id: item.id)
    DiscourseCosmeticsStore::Catalog.bump!

    sign_in(user)
    get "/cosmetics-store/inventory.json", params: { scope: "collections" }

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("inventory", "items")).to eq([])
    expect(response.parsed_body["collections"].map { |row| row["slug"] }).to include("scope-set")
  end

  it "reports the current equipped item and selection capability" do
    skip_unless_selection_actions_supported!
    item = create_item("Equipped frame")
    DiscourseUserCosmetics::UserItem.create!(user_id: user.id, item_id: item.id)
    DiscourseUserCosmetics::Integration.equip!(user: user, item: item)

    sign_in(user)
    get "/cosmetics-store/inventory.json"

    expect(response.status).to eq(200)
    payload = response.parsed_body
    row = payload.dig("inventory", "items").find { |candidate| candidate["id"] == item.id }
    expect(row["equipped"]).to eq(true)
    expect(payload.dig("viewer", "can_manage_selection")).to eq(true)
  end

  it "equips an entitled cosmetic through the Base integration contract" do
    skip_unless_selection_actions_supported!
    item = create_item("Quick equip frame")
    group = Fabricate(:group)
    item.item_groups.create!(group: group)
    GroupUser.create!(group: group, user: user)

    sign_in(user)
    put "/cosmetics-store/inventory/#{item.id}/equip.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("equipped_item_ids", "avatar_frame")).to eq(item.id)
    selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(item.id)
  end

  it "rejects equip when the cosmetic is not entitled and preserves the selection" do
    skip_unless_selection_actions_supported!
    current = create_item("Current frame")
    unavailable = create_item("Restricted frame")
    group = Fabricate(:group)
    unavailable.item_groups.create!(group: group)
    DiscourseUserCosmetics::UserItem.create!(user_id: user.id, item_id: current.id)
    DiscourseUserCosmetics::Integration.equip!(user: user, item: current)

    sign_in(user)
    put "/cosmetics-store/inventory/#{unavailable.id}/equip.json"

    expect(response.status).to eq(403)
    selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(current.id)
  end

  it "unequips one cosmetic kind without changing other slots" do
    skip_unless_selection_actions_supported!
    frame = create_item("Frame to remove")
    nameplate = create_item("Plate to keep", kind: "nameplate")
    [frame, nameplate].each do |item|
      DiscourseUserCosmetics::UserItem.create!(user_id: user.id, item_id: item.id)
      DiscourseUserCosmetics::Integration.equip!(user: user, item: item)
    end

    sign_in(user)
    delete "/cosmetics-store/inventory/avatar_frame/equip.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("equipped_item_ids", "avatar_frame")).to be_nil
    expect(response.parsed_body.dig("equipped_item_ids", "nameplate")).to eq(nameplate.id)
    selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
    expect(selection.avatar_frame_item_id).to be_nil
    expect(selection.nameplate_item_id).to eq(nameplate.id)
  end

  it "requires authentication for selection mutations" do
    skip_unless_selection_actions_supported!
    item = create_item("Private action frame")

    put "/cosmetics-store/inventory/#{item.id}/equip.json"

    expect(response.status).to eq(403)
  end

  def skip_unless_selection_actions_supported!
    skip "base cosmetics selection integration is unavailable" unless DiscourseCosmeticsStore::CosmeticsAccess.selection_actions_supported?
  end

  def create_item(name, kind: "avatar_frame")
    DiscourseUserCosmetics::Item.create!(kind: kind, name: name, enabled: true)
  end

  def create_collection_product(item, slug)
    product =
      DiscourseCosmeticsStore::Product.create!(
        name: "Store #{item.name}",
        product_type: "item",
        price: 100,
        enabled: true,
        exclusive: true,
        collection_name: "Night Set",
        collection_slug: slug,
      )
    DiscourseCosmeticsStore::ProductItem.create!(
      product: product,
      cosmetic_item: item,
      position: 0,
    )
    product
  end
end
