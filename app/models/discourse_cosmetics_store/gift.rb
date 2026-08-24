# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Gift < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_gifts"

    belongs_to :sender, class_name: "::User"
    belongs_to :recipient, class_name: "::User"
    belongs_to :product,
               class_name: "::DiscourseCosmeticsStore::Product",
               inverse_of: :gifts

    validates :recipient_id, uniqueness: { scope: :product_id }
    validates :price_paid, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: %w[completed refunded] }
    validates :idempotency_key, presence: true, uniqueness: true, length: { maximum: 190 }
    validate :sender_and_recipient_are_different

    private

    def sender_and_recipient_are_different
      errors.add(:recipient_id, :invalid) if sender_id.present? && sender_id == recipient_id
    end
  end
end
