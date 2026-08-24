# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentEvent < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_payment_events"

    belongs_to :payment,
               class_name: "::DiscourseCosmeticsStore::Payment",
               optional: true,
               inverse_of: :events

    validates :provider, inclusion: { in: OrbPackage::PROVIDERS }
    validates :external_id, presence: true, uniqueness: { scope: :provider }, length: { maximum: 190 }
    validates :payload_digest, presence: true, format: { with: /\A[0-9a-f]{64}\z/ }
    validates :status, inclusion: { in: %w[received processing completed ignored failed] }
    validates :error_message, length: { maximum: 500 }, allow_blank: true
  end
end
