# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Payment < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_payments"

    PROVIDERS = OrbPackage::PROVIDERS
    STATUSES = %w[pending processing completed failed cancelled expired refunded].freeze

    belongs_to :user, class_name: "::User"
    belongs_to :orb_package,
               class_name: "::DiscourseCosmeticsStore::OrbPackage",
               inverse_of: :payments
    has_many :events,
             class_name: "::DiscourseCosmeticsStore::PaymentEvent",
             dependent: :restrict_with_error,
             inverse_of: :payment

    validates :token, presence: true, uniqueness: true, length: { maximum: 64 }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :status, inclusion: { in: STATUSES }
    validates :orb_amount, :amount_minor,
              numericality: { only_integer: true, greater_than: 0 }
    validates :currency, inclusion: { in: OrbPackage::CURRENCIES }
    validates :provider_payment_id,
              uniqueness: { scope: :provider },
              length: { maximum: 190 },
              allow_blank: true
    validates :checkout_url, length: { maximum: 2000 }, allow_blank: true
    validates :failure_message, length: { maximum: 500 }, allow_blank: true

    scope :recent, -> { order(created_at: :desc) }

    def complete?
      status == "completed"
    end

    def terminal?
      %w[completed failed cancelled expired refunded].include?(status)
    end
  end
end

# == Schema Information
#
# Table name: discourse_cosmetics_store_payments
#
#  id                  :bigint           not null, primary key
#  amount_minor        :bigint           not null
#  checkout_url        :string(2000)
#  completed_at        :datetime
#  currency            :string(3)        not null
#  expires_at          :datetime
#  failure_code        :string(100)
#  failure_message     :string(500)
#  metadata            :jsonb            not null
#  orb_amount          :bigint           not null
#  provider            :string(24)       not null
#  status              :string(24)       default("pending"), not null
#  token               :string(64)       not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  orb_package_id      :integer          not null
#  provider_payment_id :string(190)
#  user_id             :integer          not null
#
# Indexes
#
#  idx_dcs_payments_provider_external  (provider,provider_payment_id) UNIQUE WHERE (provider_payment_id IS NOT NULL)
#  idx_dcs_payments_token              (token) UNIQUE
#  idx_dcs_payments_user_created       (user_id,created_at)
#
