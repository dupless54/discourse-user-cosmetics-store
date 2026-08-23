# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Favorite < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_favorites"

    belongs_to :product,
               class_name: "::DiscourseCosmeticsStore::Product",
               inverse_of: :favorites
    belongs_to :user, class_name: "::User"

    validates :user_id, uniqueness: { scope: :product_id }
  end
end
