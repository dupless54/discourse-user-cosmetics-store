# frozen_string_literal: true

class AddPaymentsToDiscourseCosmeticsStore < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_cosmetics_store_orb_packages do |t|
      t.string :name, null: false, limit: 120
      t.string :description, limit: 500
      t.bigint :orb_amount, null: false
      t.bigint :price_minor, null: false
      t.string :currency, null: false, default: "TRY", limit: 3
      t.jsonb :provider_config, null: false, default: {}
      t.integer :sort_order, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.boolean :featured, null: false, default: false
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_orb_packages,
              %i[enabled sort_order id],
              name: "idx_dcs_orb_packages_catalog"

    create_table :discourse_cosmetics_store_payments do |t|
      t.string :token, null: false, limit: 64
      t.integer :user_id, null: false
      t.integer :orb_package_id, null: false
      t.string :provider, null: false, limit: 24
      t.string :status, null: false, default: "pending", limit: 24
      t.bigint :orb_amount, null: false
      t.bigint :amount_minor, null: false
      t.string :currency, null: false, limit: 3
      t.string :provider_payment_id, limit: 190
      t.string :checkout_url, limit: 2000
      t.jsonb :metadata, null: false, default: {}
      t.string :failure_code, limit: 100
      t.string :failure_message, limit: 500
      t.datetime :completed_at
      t.datetime :expires_at
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_payments,
              :token,
              unique: true,
              name: "idx_dcs_payments_token"
    add_index :discourse_cosmetics_store_payments,
              %i[user_id created_at],
              name: "idx_dcs_payments_user_created"
    add_index :discourse_cosmetics_store_payments,
              %i[provider provider_payment_id],
              unique: true,
              where: "provider_payment_id IS NOT NULL",
              name: "idx_dcs_payments_provider_external"

    create_table :discourse_cosmetics_store_payment_events do |t|
      t.integer :payment_id
      t.string :provider, null: false, limit: 24
      t.string :external_id, null: false, limit: 190
      t.string :payload_digest, null: false, limit: 64
      t.string :status, null: false, default: "received", limit: 24
      t.string :error_message, limit: 500
      t.datetime :processed_at
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_payment_events,
              %i[provider external_id],
              unique: true,
              name: "idx_dcs_payment_events_unique"
    add_index :discourse_cosmetics_store_payment_events,
              :payment_id,
              name: "idx_dcs_payment_events_payment"
  end
end
