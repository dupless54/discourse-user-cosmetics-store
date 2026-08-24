# frozen_string_literal: true

class AddRefundsToDiscourseCosmeticsStore < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_cosmetics_store_wallets,
               :debt,
               :bigint,
               null: false,
               default: 0

    add_column :discourse_cosmetics_store_ledger_entries,
               :debt_delta,
               :bigint,
               null: false,
               default: 0
    add_column :discourse_cosmetics_store_ledger_entries,
               :debt_after,
               :bigint,
               null: false,
               default: 0

    add_column :discourse_cosmetics_store_payments,
               :refunded_amount_minor,
               :bigint,
               null: false,
               default: 0
    add_column :discourse_cosmetics_store_payments,
               :refunded_orb_amount,
               :bigint,
               null: false,
               default: 0
    add_column :discourse_cosmetics_store_payments, :refunded_at, :datetime

    create_table :discourse_cosmetics_store_payment_refunds do |t|
      t.integer :payment_id, null: false
      t.integer :created_by_id
      t.string :provider, null: false, limit: 24
      t.string :provider_refund_id, null: false, limit: 190
      t.string :status, null: false, default: "requested", limit: 24
      t.string :source, null: false, default: "webhook", limit: 24
      t.bigint :amount_minor, null: false
      t.bigint :orb_amount, null: false, default: 0
      t.string :currency, null: false, limit: 3
      t.jsonb :metadata, null: false, default: {}
      t.datetime :completed_at
      t.timestamps null: false
    end

    add_index :discourse_cosmetics_store_payment_refunds,
              %i[provider provider_refund_id],
              unique: true,
              name: "idx_dcs_payment_refunds_provider_external"
    add_index :discourse_cosmetics_store_payment_refunds,
              %i[payment_id created_at],
              name: "idx_dcs_payment_refunds_payment"
  end
end
