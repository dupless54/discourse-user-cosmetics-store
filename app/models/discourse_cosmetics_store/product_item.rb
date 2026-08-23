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
