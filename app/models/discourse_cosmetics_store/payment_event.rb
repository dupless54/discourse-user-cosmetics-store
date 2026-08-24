# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentEvent < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_payment_events"

    belongs_to :payment,
               class_name: "::DiscourseCosmeticsStore::Payment",
               optional: true,
               inverse_of: :events

    validates :provider, inclusion: { in: OrbPackage::PROVIDERS }
    validates :external_id, presence: true, length: { maximum: 190 }
    validates :payload_digest, presence: true, format: { with: /\A[0-9a-f]{64}\z/ }
    validates :status, inclusion: { in: %w[received processing completed ignored failed] }
    validates :error_message, length: { maximum: 500 }, allow_blank: true
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_payment_events
#
#  id             :bigint           not null, primary key
#  error_message  :string(500)
#  payload_digest :string(64)       not null
#  processed_at   :datetime
#  provider       :string(24)       not null
#  status         :string(24)       default("received"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  external_id    :string(190)      not null
#  payment_id     :bigint
#
# Indexes
#
#  idx_dcs_payment_events_payment  (payment_id)
#  idx_dcs_payment_events_unique   (provider,external_id) UNIQUE
#
