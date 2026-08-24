# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class ProductItem < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_product_items"

    belongs_to :product,
               class_name: "::DiscourseCosmeticsStore::Product",
               inverse_of: :product_items
    belongs_to :cosmetic_item,
               class_name: "::DiscourseUserCosmetics::Item"

    validates :cosmetic_item_id, uniqueness: { scope: :product_id }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_product_items
#
#  id               :bigint           not null, primary key
#  position         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cosmetic_item_id :bigint           not null
#  product_id       :bigint           not null
#
# Indexes
#
#  idx_dcs_product_items_cosmetic  (cosmetic_item_id)
#  idx_dcs_product_items_unique    (product_id,cosmetic_item_id) UNIQUE
#
