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

# == Schema Information
#
# Table name: discourse_cosmetics_store_gifts
#
#  id              :bigint           not null, primary key
#  idempotency_key :string(190)      not null
#  price_paid      :integer          not null
#  status          :string(20)       default("completed"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :integer          not null
#  recipient_id    :integer          not null
#  sender_id       :integer          not null
#
# Indexes
#
#  idx_dcs_gifts_idempotency        (idempotency_key) UNIQUE
#  idx_dcs_gifts_recipient_product  (recipient_id,product_id) UNIQUE
#  idx_dcs_gifts_sender_created     (sender_id,created_at)
#
