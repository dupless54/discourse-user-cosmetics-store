# frozen_string_literal: true

RSpec.describe DiscourseCosmeticsStore::StoreController do
  fab!(:user)
  fab!(:recipient, :user)

  let(:now) { Time.zone.parse("2026-08-29 12:00:00") }

  before do
    SiteSetting.discourse_cosmetics_store_enabled = true
    SiteSetting.discourse_cosmetics_store_starting_balance = 100
    sign_in(user)
  end

  def product_with_item!(name:, **attributes)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "#{name} item")
    product =
      DiscourseCosmeticsStore::Product.create!(
        {
          name: name,
          product_type: "item",
          price: 25,
          exclusive: true,
        }.merge(attributes),
      )
    DiscourseCosmeticsStore::ProductItem.create!(
      product: product,
      cosmetic_item: item,
      position: 0,
    )
    [product, item]
  end

  it "shows upcoming seasonal products in browse data but excludes expired products and promotions" do
    travel_to(now) do
      active, =
        product_with_item!(
          name: "Limited Active",
          featured: true,
          rarity_label: "Efsanevi",
          available_until: now + 2.days,
        )
      upcoming, =
        product_with_item!(
          name: "Seasonal Upcoming",
          featured: true,
          available_from: now + 1.hour,
          available_until: now + 3.days,
        )
      expired, =
        product_with_item!(
          name: "Expired Seasonal",
          available_from: now - 3.days,
          available_until: now - 1.hour,
        )

      get "/cosmetics-store.json"

      expect(response.status).to eq(200)
      payload = response.parsed_body
      products = payload["products"].index_by { |product| product["id"] }

      expect(products.keys).to include(active.id, upcoming.id)
      expect(products.keys).not_to include(expired.id)
      expect(products.dig(active.id, "availability_type")).to eq("limited")
      expect(products.dig(active.id, "sale_state")).to eq("active")
      expect(products.dig(upcoming.id, "availability_type")).to eq("seasonal")
      expect(products.dig(upcoming.id, "sale_state")).to eq("upcoming")
      expect(products.dig(upcoming.id, "purchasable")).to eq(false)
      expect(products.dig(upcoming.id, "giftable")).to eq(false)
      expect(payload.dig("sections", "featured")).to include(active.id)
      expect(payload.dig("sections", "featured")).not_to include(upcoming.id)
      expect(payload.dig("filters", "availability").map { |row| row["value"] }).to include(
        "limited",
        "seasonal",
        "upcoming",
      )
    end
  end

  it "rejects purchase and gift before a seasonal window opens without changing wallet or ownership" do
    travel_to(now) do
      upcoming, item =
        product_with_item!(
          name: "Future Seasonal",
          available_from: now + 1.hour,
          available_until: now + 2.days,
        )
      wallet = DiscourseCosmeticsStore::WalletService.fetch(user)
      starting_balance = wallet.balance

      post "/cosmetics-store/products/#{upcoming.id}/purchase.json"
      expect(response.status).to eq(422)
      expect(wallet.reload.balance).to eq(starting_balance)
      expect(DiscourseUserCosmetics::UserItem.exists?(user_id: user.id, item_id: item.id)).to eq(false)

      post "/cosmetics-store/products/#{upcoming.id}/gift.json",
           params: { username: recipient.username }
      expect(response.status).to eq(422)
      expect(wallet.reload.balance).to eq(starting_balance)
      expect(
        DiscourseUserCosmetics::UserItem.exists?(user_id: recipient.id, item_id: item.id),
      ).to eq(false)
    end
  end
end
