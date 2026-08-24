# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Payment < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_payments"

    PROVIDERS = OrbPackage::PROVIDERS
    STATUSES = %w[pending processing completed partially_refunded failed cancelled expired refunded].freeze

    belongs_to :user, class_name: "::User"
    belongs_to :orb_package,
               class_name: "::DiscourseCosmeticsStore::OrbPackage",
               inverse_of: :payments
    has_many :events,
             class_name: "::DiscourseCosmeticsStore::PaymentEvent",
             dependent: :restrict_with_error,
             inverse_of: :payment
    has_many :refunds,
             class_name: "::DiscourseCosmeticsStore::PaymentRefund",
             dependent: :restrict_with_error,
             inverse_of: :payment

    validates :token, presence: true, uniqueness: true, length: { maximum: 64 }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :status, inclusion: { in: STATUSES }
    validates :orb_amount, :amount_minor,
              numericality: { only_integer: true, greater_than: 0 }
    validates :refunded_amount_minor,
              :refunded_orb_amount,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :currency, inclusion: { in: OrbPackage::CURRENCIES }
    validates :provider_payment_id,
              uniqueness: { scope: :provider },
              length: { maximum: 190 },
              allow_blank: true
    validates :checkout_url, length: { maximum: 2000 }, allow_blank: true
    validates :failure_message, length: { maximum: 500 }, allow_blank: true
    validate :refund_totals_do_not_exceed_payment

    scope :recent, -> { order(created_at: :desc) }

    def complete?
      %w[completed partially_refunded refunded].include?(status)
    end

    def refundable?
      %w[completed partially_refunded].include?(status) &&
        refunded_amount_minor.to_i < amount_minor.to_i
    end

    def terminal?
      %w[completed partially_refunded failed cancelled expired refunded].include?(status)
    end

    private

    def refund_totals_do_not_exceed_payment
      if refunded_amount_minor.to_i > amount_minor.to_i
        errors.add(:refunded_amount_minor, "ödeme tutarını aşamaz")
      end
      if refunded_orb_amount.to_i > orb_amount.to_i
        errors.add(:refunded_orb_amount, "satın alınan Orb miktarını aşamaz")
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_payments
#
#  id                    :bigint           not null, primary key
#  amount_minor          :bigint           not null
#  checkout_url          :string(2000)
#  completed_at          :datetime
#  currency              :string(3)        not null
#  expires_at            :datetime
#  failure_code          :string(100)
#  failure_message       :string(500)
#  metadata              :jsonb            not null
#  orb_amount            :bigint           not null
#  provider              :string(24)       not null
#  refunded_amount_minor :bigint           default(0), not null
#  refunded_at           :datetime
#  refunded_orb_amount   :bigint           default(0), not null
#  status                :string(24)       default("pending"), not null
#  token                 :string(64)       not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  orb_package_id        :integer          not null
#  provider_payment_id   :string(190)
#  user_id               :integer          not null
#
# Indexes
#
#  idx_dcs_payments_provider_external  (provider,provider_payment_id) UNIQUE WHERE (provider_payment_id IS NOT NULL)
#  idx_dcs_payments_token              (token) UNIQUE
#  idx_dcs_payments_user_created       (user_id,created_at)
#
