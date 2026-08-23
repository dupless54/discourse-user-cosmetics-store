# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Purchase < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_purchases"

    belongs_to :user, class_name: "::User"
    belongs_to :product,
               class_name: "::DiscourseCosmeticsStore::Product",
               inverse_of: :purchases

    validates :user_id, uniqueness: { scope: :product_id }
    validates :price_paid, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: %w[completed refunded] }
    validates :idempotency_key, presence: true, uniqueness: true, length: { maximum: 190 }
  end
end
