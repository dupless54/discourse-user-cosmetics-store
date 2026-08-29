# frozen_string_literal: true

RSpec.describe "Cosmetics Store loadouts" do
  fab!(:user)
  fab!(:other_user, :user)

  before do
    skip "base cosmetics loadout contract is not installed in this test job" unless loadouts_supported?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
  end

  it "creates, renames, applies, lists, and deletes a current-user loadout" do
    frame = create_item("Saved frame", "avatar_frame")
    plate = create_item("Saved plate", "nameplate")
    integration.grant!(user: user, item: frame)
    integration.grant!(user: user, item: plate)
    integration.equip!(user: user, item: frame)
    integration.equip!(user: user, item: plate)

    sign_in(user)
    post "/cosmetics-store/loadouts.json", params: { name: "Night set" }

    expect(response.status).to eq(201)
    loadout_id = response.parsed_body.dig("loadout", "id")
    expect(response.parsed_body.dig("loadout", "name")).to eq("Night set")
    expect(response.parsed_body.dig("loadout", "slots", "avatar_frame", "item_id")).to eq(frame.id)
    expect(response.parsed_body.dig("loadout", "slots", "nameplate", "item_id")).to eq(plate.id)

    put "/cosmetics-store/loadouts/#{loadout_id}.json", params: { name: "Night set v2" }
    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("loadout", "name")).to eq("Night set v2")

    integration.unequip!(user: user, kind: "avatar_frame")
    integration.unequip!(user: user, kind: "nameplate")

    post "/cosmetics-store/loadouts/#{loadout_id}/apply.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("loadout", "id")).to eq(loadout_id)

    selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(frame.id)
    expect(selection.nameplate_item_id).to eq(plate.id)

    get "/cosmetics-store/loadouts.json"
    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body["loadouts"].map { |row| row["id"] }).to include(loadout_id)

    delete "/cosmetics-store/loadouts/#{loadout_id}.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["deleted"]).to eq(true)
    expect(integration.loadouts_for(user: user)).to be_empty
  end

  it "does not allow one user to mutate another user's loadout" do
    foreign = integration.create_loadout!(user: other_user, name: "Private set")
    sign_in(user)

    put "/cosmetics-store/loadouts/#{foreign[:id]}.json", params: { name: "Taken over" }
    expect(response.status).to eq(404)

    post "/cosmetics-store/loadouts/#{foreign[:id]}/apply.json"
    expect(response.status).to eq(404)

    delete "/cosmetics-store/loadouts/#{foreign[:id]}.json"
    expect(response.status).to eq(404)

    expect(integration.loadouts_for(user: other_user).first[:name]).to eq("Private set")
  end

  it "rejects an unavailable saved set without changing the current selection" do
    saved_frame = create_item("Saved frame", "avatar_frame")
    current_frame = create_item("Current frame", "avatar_frame")
    restricted_group = Fabricate(:group)
    DiscourseUserCosmetics::ItemGroup.create!(item_id: saved_frame.id, group_id: restricted_group.id)

    integration.grant!(user: user, item: saved_frame)
    integration.grant!(user: user, item: current_frame)
    integration.equip!(user: user, item: saved_frame)
    loadout = integration.create_loadout!(user: user, name: "Unavailable set")

    integration.equip!(user: user, item: current_frame)
    integration.revoke!(user: user, item: saved_frame)

    sign_in(user)
    post "/cosmetics-store/loadouts/#{loadout[:id]}/apply.json"

    expect(response.status).to eq(422)
    selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(current_frame.id)
  end

  def loadouts_supported?
    return false unless DiscourseCosmeticsStore.load_base_plugin!
    return false unless defined?(DiscourseUserCosmetics::Integration)

    integration.respond_to?(:loadouts_supported?) && integration.loadouts_supported?
  end

  def integration
    DiscourseUserCosmetics::Integration
  end

  def create_item(name, kind)
    DiscourseUserCosmetics::Item.create!(kind: kind, name: name, enabled: true)
  end
end
