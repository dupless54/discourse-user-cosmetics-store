# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentRefund < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_payment_refunds"

    STATUSES = %w[requested processing completed failed].freeze
    SOURCES = %w[webhook manual].freeze

    belongs_to :payment,
               class_name: "::DiscourseCosmeticsStore::Payment",
               inverse_of: :refunds
    belongs_to :created_by, class_name: "::User", optional: true

    validates :provider, inclusion: { in: OrbPackage::PROVIDERS }
    validates :provider_refund_id,
              presence: true,
              uniqueness: { scope: :provider },
              length: { maximum: 190 }
    validates :status, inclusion: { in: STATUSES }
    validates :source, inclusion: { in: SOURCES }
    validates :amount_minor,
              numericality: { only_integer: true, greater_than: 0 }
    validates :orb_amount,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :currency, inclusion: { in: OrbPackage::CURRENCIES }
    validate :provider_and_currency_match_payment
    validate :amount_does_not_exceed_payment

    def completed?
      status == "completed"
    end

    private

    def provider_and_currency_match_payment
      return unless payment

      errors.add(:provider, "ödeme sağlayıcısıyla eşleşmiyor") if provider != payment.provider
      errors.add(:currency, "ödeme para birimiyle eşleşmiyor") if currency != payment.currency
    end

    def amount_does_not_exceed_payment
      return unless payment && amount_minor.to_i > payment.amount_minor.to_i

      errors.add(:amount_minor, "ödeme tutarını aşamaz")
    end
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_payment_refunds
#
#  id                 :bigint           not null, primary key
#  amount_minor       :bigint           not null
#  completed_at       :datetime
#  currency           :string(3)        not null
#  metadata           :jsonb            not null
#  orb_amount         :bigint           default(0), not null
#  provider           :string(24)       not null
#  source             :string(24)       default("webhook"), not null
#  status             :string(24)       default("requested"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_id      :bigint
#  payment_id         :bigint           not null
#  provider_refund_id :string(190)      not null
#
# Indexes
#
#  idx_dcs_payment_refunds_payment            (payment_id,created_at)
#  idx_dcs_payment_refunds_provider_external  (provider,provider_refund_id) UNIQUE
#
