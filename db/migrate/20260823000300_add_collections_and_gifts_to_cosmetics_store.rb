# frozen_string_literal: true

class AddCollectionsAndGiftsToCosmeticsStore < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_cosmetics_store_products, :collection_name, :string, limit: 120
    add_column :discourse_cosmetics_store_products, :collection_slug, :string, limit: 140
    add_column :discourse_cosmetics_store_products, :collection_image_url, :string, limit: 1000

    add_index :discourse_cosmetics_store_products,
              %i[collection_slug enabled sort_order],
              name: "idx_dcs_products_collection"

    create_table :discourse_cosmetics_store_gifts do |t|
      t.integer :sender_id, null: false
      t.integer :recipient_id, null: false
      t.integer :product_id, null: false
      t.integer :price_paid, null: false
      t.string :status, null: false, default: "completed", limit: 20
      t.string :idempotency_key, null: false, limit: 190
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_gifts,
              %i[recipient_id product_id],
              unique: true,
              name: "idx_dcs_gifts_recipient_product"
    add_index :discourse_cosmetics_store_gifts,
              :idempotency_key,
              unique: true,
              name: "idx_dcs_gifts_idempotency"
    add_index :discourse_cosmetics_store_gifts,
              %i[sender_id created_at],
              name: "idx_dcs_gifts_sender_created"
  end
end
