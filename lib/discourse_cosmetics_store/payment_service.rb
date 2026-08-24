# frozen_string_literal: true

require "securerandom"

module ::DiscourseCosmeticsStore
  class PaymentService
    class Disabled < StandardError; end
    class Unavailable < StandardError; end

    attr_reader :user, :orb_package, :provider, :request_context, :billing, :payment

    def initialize(user:, orb_package:, provider:, request_context:, billing: {})
      @user = user
      @orb_package = orb_package
      @provider = provider.to_s
      @request_context = request_context
      @billing = billing
    end

    def call
      raise Disabled unless SiteSetting.discourse_cosmetics_store_payments_enabled
      raise Unavailable unless orb_package.enabled? && orb_package.provider_enabled?(provider)

      adapter_class = PaymentProviders.fetch(provider)
      raise PaymentProviders::ConfigurationError, "Ödeme sağlayıcısı etkin veya eksiksiz yapılandırılmış değil" unless adapter_class.configured?

      RateLimiter.new(user, "cosmetics-store-payment", 8, 1.minute).performed!
      @payment = Payment.create!(
        token: SecureRandom.hex(24),
        user_id: user.id,
        orb_package_id: orb_package.id,
        provider: provider,
        status: "pending",
        orb_amount: orb_package.orb_amount,
        amount_minor: orb_package.price_minor,
        currency: orb_package.currency,
        expires_at: 45.minutes.from_now,
        metadata: {},
      )

      checkout = adapter_class.new(
        payment: payment,
        user: user,
        request_context: request_context,
        billing: billing,
      ).create_checkout
      PaymentProviders.validate_checkout_url!(provider, checkout.checkout_url)

      payment.update!(
        provider_payment_id: checkout.provider_payment_id,
        checkout_url: checkout.checkout_url,
        metadata: checkout.metadata || {},
      )
      self
    rescue StandardError => error
      payment&.update_columns(
        status: "failed",
        failure_code: error.class.name.demodulize[0, 100],
        failure_message: error.message.to_s[0, 500],
        updated_at: Time.zone.now,
      )
      raise
    end
  end
end
