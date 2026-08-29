# frozen_string_literal: true

RSpec.describe "Cosmetics Store preview studio" do
  fab!(:user)

  before do
    skip "base cosmetics preview contract is not installed in this test job" unless preview_supported?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
  end

  it "returns only entitled preview items with current selections and private cache headers" do
    frame = create_item("Available frame", "avatar_frame")
    restricted_plate = create_item("Restricted plate", "nameplate")
    restricted_plate.item_groups.create!(group: Fabricate(:group))
    integration.equip!(user: user, item: frame)

    sign_in(user)
    get "/cosmetics-store/preview.json"

    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body["items"].map { |item| item["id"] }).to include(frame.id)
    expect(response.parsed_body["items"].map { |item| item["id"] }).not_to include(restricted_plate.id)
    expect(response.parsed_body.dig("selections", "avatar_frame")).to eq(frame.id)
    expect(response.parsed_body.dig("viewer", "username")).to eq(user.username)
  end

  it "applies all four preview slots through the atomic base contract" do
    frame = create_item("Frame", "avatar_frame")
    plate = create_item("Plate", "nameplate")
    card = create_item("Card", "card_decoration")
    effect = create_item("Effect", "profile_effect")

    sign_in(user)
    post "/cosmetics-store/preview/apply.json",
         params: {
           selections: {
             avatar_frame: frame.id,
             nameplate: plate.id,
             card_decoration: card.id,
             profile_effect: effect.id,
           },
         }

    expect(response.status).to eq(200)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body["selections"]).to eq(
      "avatar_frame" => frame.id,
      "nameplate" => plate.id,
      "card_decoration" => card.id,
      "profile_effect" => effect.id,
    )
    expect(response.parsed_body.dig("cosmetics", "avatar_frame", "id")).to eq(frame.id)
    expect(response.parsed_body.dig("cosmetics", "profile_effect", "id")).to eq(effect.id)
  end

  it "rejects one unavailable preview slot without partially changing the current look" do
    old_frame = create_item("Old frame", "avatar_frame")
    old_plate = create_item("Old plate", "nameplate")
    new_frame = create_item("New frame", "avatar_frame")
    restricted_plate = create_item("Restricted plate", "nameplate")
    restricted_plate.item_groups.create!(group: Fabricate(:group))

    integration.apply_selections!(
      user: user,
      selections: {
        avatar_frame: old_frame.id,
        nameplate: old_plate.id,
        card_decoration: nil,
        profile_effect: nil,
      },
    )

    sign_in(user)
    post "/cosmetics-store/preview/apply.json",
         params: {
           selections: {
             avatar_frame: new_frame.id,
             nameplate: restricted_plate.id,
             card_decoration: nil,
             profile_effect: nil,
           },
         }

    expect(response.status).to eq(422)
    expect(integration.current_selections_for(user: user)).to eq(
      "avatar_frame" => old_frame.id,
      "nameplate" => old_plate.id,
      "card_decoration" => nil,
      "profile_effect" => nil,
    )
  end

  def preview_supported?
    return false unless DiscourseCosmeticsStore.load_base_plugin!
    return false unless defined?(DiscourseUserCosmetics::Integration)

    integration.respond_to?(:current_selections_for) && integration.respond_to?(:apply_selections!)
  end

  def integration
    DiscourseUserCosmetics::Integration
  end

  def create_item(name, kind)
    DiscourseUserCosmetics::Item.create!(kind: kind, name: name, enabled: true)
  end
end
