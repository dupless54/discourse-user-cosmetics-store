# frozen_string_literal: true

class CreateDiscourseCosmeticsStore < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_cosmetics_store_products do |t|
      t.string :name, null: false, limit: 120
      t.string :slug, null: false, limit: 140
      t.text :description
      t.string :product_type, null: false, default: "item", limit: 20
      t.integer :price, null: false, default: 0
      t.string :card_image_url, limit: 1000
      t.string :hero_image_url, limit: 1000
      t.string :preview_background_url, limit: 1000
      t.string :rarity_label, limit: 40
      t.string :rarity_color, limit: 20
      t.jsonb :tags, null: false, default: []
      t.integer :sort_order, null: false, default: 0
      t.integer :purchase_count, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.boolean :featured, null: false, default: false
      t.boolean :editor_pick, null: false, default: false
      t.boolean :exclusive, null: false, default: true
      t.datetime :available_from
      t.datetime :available_until
      t.integer :created_by_id
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_products, :slug, unique: true,
              name: "idx_dcs_products_slug"
    add_index :discourse_cosmetics_store_products,
              %i[enabled featured editor_pick sort_order],
              name: "idx_dcs_products_catalog"
    add_index :discourse_cosmetics_store_products, :tags, using: :gin,
              name: "idx_dcs_products_tags"

    create_table :discourse_cosmetics_store_product_items do |t|
      t.integer :product_id, null: false
      t.integer :cosmetic_item_id, null: false
      t.integer :position, null: false, default: 0
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_product_items,
              %i[product_id cosmetic_item_id], unique: true,
              name: "idx_dcs_product_items_unique"
    add_index :discourse_cosmetics_store_product_items, :cosmetic_item_id,
              name: "idx_dcs_product_items_cosmetic"

    create_table :discourse_cosmetics_store_wallets do |t|
      t.integer :user_id, null: false
      t.bigint :balance, null: false, default: 0
      t.bigint :lifetime_earned, null: false, default: 0
      t.bigint :lifetime_spent, null: false, default: 0
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_wallets, :user_id, unique: true,
              name: "idx_dcs_wallets_user"

    create_table :discourse_cosmetics_store_ledger_entries do |t|
      t.integer :wallet_id, null: false
      t.integer :user_id, null: false
      t.bigint :amount, null: false
      t.bigint :balance_after, null: false
      t.string :entry_type, null: false, limit: 30
      t.string :reference_type, limit: 60
      t.integer :reference_id
      t.string :idempotency_key, null: false, limit: 190
      t.string :reason, limit: 500
      t.integer :created_by_id
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_ledger_entries, :idempotency_key,
              unique: true, name: "idx_dcs_ledger_idempotency"
    add_index :discourse_cosmetics_store_ledger_entries,
              %i[user_id created_at], name: "idx_dcs_ledger_user_created"

    create_table :discourse_cosmetics_store_purchases do |t|
      t.integer :user_id, null: false
      t.integer :product_id, null: false
      t.integer :price_paid, null: false
      t.string :status, null: false, default: "completed", limit: 20
      t.string :idempotency_key, null: false, limit: 190
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_purchases, %i[user_id product_id],
              unique: true, name: "idx_dcs_purchases_user_product"
    add_index :discourse_cosmetics_store_purchases, :idempotency_key,
              unique: true, name: "idx_dcs_purchases_idempotency"

    create_table :discourse_cosmetics_store_missions do |t|
      t.string :key, null: false, limit: 100
      t.string :name, null: false, limit: 120
      t.string :description, limit: 500
      t.string :metric, null: false, limit: 40
      t.integer :target, null: false, default: 1
      t.integer :reward, null: false, default: 0
      t.string :icon, limit: 20
      t.integer :sort_order, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.datetime :available_from
      t.datetime :available_until
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_missions, :key, unique: true,
              name: "idx_dcs_missions_key"
    add_index :discourse_cosmetics_store_missions, %i[enabled sort_order],
              name: "idx_dcs_missions_enabled_sort"

    create_table :discourse_cosmetics_store_mission_claims do |t|
      t.integer :mission_id, null: false
      t.integer :user_id, null: false
      t.integer :progress_at_claim, null: false
      t.integer :reward, null: false
      t.string :idempotency_key, null: false, limit: 190
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_mission_claims,
              %i[mission_id user_id], unique: true,
              name: "idx_dcs_mission_claim_once"
    add_index :discourse_cosmetics_store_mission_claims, :idempotency_key,
              unique: true, name: "idx_dcs_mission_claim_idempotency"

    create_table :discourse_cosmetics_store_favorites do |t|
      t.integer :product_id, null: false
      t.integer :user_id, null: false
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_favorites, %i[user_id product_id],
              unique: true, name: "idx_dcs_favorites_user_product"
  end
end
