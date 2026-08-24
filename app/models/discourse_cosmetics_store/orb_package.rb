# frozen_string_literal: true

require "uri"

module ::DiscourseCosmeticsStore
  class OrbPackage < ActiveRecord::Base
    self.table_name = "discourse_cosmetics_store_orb_packages"

    PROVIDERS = %w[stripe paypal paytr iyzico shopier shipy].freeze
    CURRENCIES = %w[TRY USD EUR GBP].freeze

    has_many :payments,
             class_name: "::DiscourseCosmeticsStore::Payment",
             dependent: :restrict_with_error,
             inverse_of: :orb_package

    validates :name, presence: true, length: { maximum: 120 }
    validates :description, length: { maximum: 500 }, allow_blank: true
    validates :orb_amount,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1_000_000_000 }
    validates :price_minor,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000_000_000 }
    validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :currency, inclusion: { in: CURRENCIES }
    validate :provider_configuration_is_safe

    before_validation :normalize_configuration

    scope :ordered, -> { order(featured: :desc, sort_order: :asc, id: :asc) }
    scope :available, -> { where(enabled: true).ordered }

    def provider_enabled?(provider)
      configured = Array(provider_config["providers"])
      configured.include?(provider.to_s)
    end

    def shopier_checkout_url
      provider_config["shopier_checkout_url"].to_s.presence
    end

    def shopier_product_id
      provider_config["shopier_product_id"].to_s.presence
    end

    private

    def normalize_configuration
      config = provider_config.is_a?(Hash) ? provider_config.deep_stringify_keys : {}
      config["providers"] = Array(config["providers"]).map(&:to_s).select { |value| PROVIDERS.include?(value) }.uniq
      config["shopier_product_id"] = config["shopier_product_id"].to_s.strip[0, 190]
      config["shopier_checkout_url"] = config["shopier_checkout_url"].to_s.strip[0, 2000]
      self.provider_config = config
      self.currency = currency.to_s.upcase
    end

    def provider_configuration_is_safe
      selected = Array(provider_config&.dig("providers"))
      if selected.blank?
        errors.add(:provider_config, "En az bir ödeme sağlayıcısı seçilmelidir")
        return
      end

      value = provider_config&.dig("shopier_checkout_url").to_s
      product_id = provider_config&.dig("shopier_product_id").to_s
      if selected.include?("shopier") && (value.blank? || product_id.blank?)
        errors.add(:provider_config, "Shopier için ürün bağlantısı ve ürün kimliği gereklidir")
        return
      end
      return if value.blank?

      uri = URI.parse(value)
      host = uri.host.to_s.downcase
      valid =
        uri.is_a?(URI::HTTPS) &&
          (host == "shopier.com" || host.end_with?(".shopier.com")) &&
          uri.userinfo.blank?
      errors.add(:provider_config, "Shopier bağlantısı geçerli bir HTTPS adresi olmalıdır") unless valid
    rescue URI::InvalidURIError
      errors.add(:provider_config, "Shopier bağlantısı geçerli değil")
    end
  end
end
