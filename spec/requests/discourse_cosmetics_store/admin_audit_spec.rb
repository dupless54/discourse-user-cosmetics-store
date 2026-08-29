# frozen_string_literal: true

RSpec.describe "Discourse Cosmetics Store admin audit" do
  fab!(:admin)
  fab!(:user)

  before do
    skip "base cosmetics plugin is not installed in this test job" unless DiscourseCosmeticsStore.base_plugin_ready?

    enable_current_plugin
    DiscourseCosmeticsStore.install_cosmetics_integration!
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_starting_balance = 0
    sign_in(admin)
  end

  def audit_rows(type)
    UserHistory.where(
      action: UserHistory.actions[:custom_staff],
      custom_type: "cosmetics_store_#{type}",
    )
  end

  it "records a successful catalog mutation and exposes it through the admin payload" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Audit frame")

    post "/admin/plugins/user-cosmetics-store/products.json",
         params: {
           product: {
             name: "Audit product",
             product_type: "item",
             price: 25,
             enabled: true,
             exclusive: true,
             cosmetic_item_ids: [item.id],
           },
         }

    expect(response.status).to eq(200)
    product_id = response.parsed_body.fetch("id")
    history = audit_rows("product_created").last
    expect(history).to be_present
    expect(history.acting_user_id).to eq(admin.id)
    expect(history.subject).to eq("product:#{product_id}")
    expect(history.details).to include("entity_name: Audit product")
    expect(history.details).to include("changed_fields:")

    get "/admin/plugins/user-cosmetics-store/catalog.json"

    expect(response.status).to eq(200)
    audit_log = response.parsed_body.fetch("audit_log")
    expect(audit_log.first.fetch("action")).to eq("product_created")
    expect(audit_log.first.dig("actor", "username")).to eq(admin.username)
  end

  it "records successful wallet adjustment metadata without copying the free-form reason" do
    secret_reason = "internal free-form reason must not enter staff audit"

    post "/admin/plugins/user-cosmetics-store/wallet/adjust.json",
         params: {
           username: user.username,
           amount: 30,
           reason: secret_reason,
         }

    expect(response.status).to eq(200)
    history = audit_rows("wallet_adjusted").last
    expect(history).to be_present
    expect(history.details).to include("target_username: #{user.username}")
    expect(history.details).to include("amount: 30")
    expect(history.details).not_to include(secret_reason)
    expect(history.details).not_to include("reason:")
  end

  it "does not create an audit row for a rejected admin mutation" do
    expect do
      post "/admin/plugins/user-cosmetics-store/wallet/adjust.json",
           params: {
             username: user.username,
             amount: 0,
             reason: "invalid adjustment",
           }
    end.not_to change { audit_rows("wallet_adjusted").count }

    expect(response.status).to eq(422)
  end
end
