# frozen_string_literal: true

class UseBigintForCosmeticsStoreReferences < ActiveRecord::Migration[7.1]
  COLUMNS = {
    discourse_cosmetics_store_products: %i[created_by_id],
    discourse_cosmetics_store_product_items: %i[product_id cosmetic_item_id],
    discourse_cosmetics_store_wallets: %i[user_id],
    discourse_cosmetics_store_ledger_entries: %i[wallet_id user_id reference_id created_by_id],
    discourse_cosmetics_store_purchases: %i[user_id product_id],
    discourse_cosmetics_store_mission_claims: %i[mission_id user_id],
    discourse_cosmetics_store_favorites: %i[product_id user_id],
    discourse_cosmetics_store_payments: %i[user_id orb_package_id],
    discourse_cosmetics_store_payment_events: %i[payment_id],
    discourse_cosmetics_store_gifts: %i[sender_id recipient_id product_id],
    discourse_cosmetics_store_payment_refunds: %i[payment_id created_by_id],
  }.freeze

  def up
    change_column_types(:bigint)
  end

  def down
    change_column_types(:integer)
  end

  private

  def change_column_types(type)
    COLUMNS.each do |table, columns|
      columns.each { |column| change_column table, column, type }
    end
  end
end
