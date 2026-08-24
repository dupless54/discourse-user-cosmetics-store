# frozen_string_literal: true

require "base64"
require "bigdecimal"
require "digest"
require "json"
require "openssl"
require "securerandom"
require "uri"

module ::DiscourseCosmeticsStore
  module PaymentProviders
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class VerificationError < Error; end

    Checkout = Struct.new(:provider_payment_id, :checkout_url, :metadata, keyword_init: true)

    PROVIDER_LABELS = {
      "stripe" => "Stripe",
      "paypal" => "PayPal",
      "paytr" => "PayTR",
      "iyzico" => "iyzico",
      "shopier" => "Shopier",
      "shipy" => "Shipy",
    }.freeze

    CHECKOUT_HOST_SUFFIXES = {
      "stripe" => ["stripe.com"],
      "paypal" => ["paypal.com"],
      "paytr" => ["paytr.com"],
      "iyzico" => ["iyzipay.com"],
      "shopier" => ["shopier.com"],
      "shipy" => ["shipy.dev", "shipy.link"],
    }.freeze

    class Base
      attr_reader :payment, :user, :request_context, :billing

      def initialize(payment: nil, user: nil, request_context: nil, billing: {})
        @payment = payment
        @user = user
        @request_context = request_context
        @billing = billing.to_h.with_indifferent_access
      end

      def self.configured?
        false
      end

      def self.setting(name)
        SiteSetting.public_send("discourse_cosmetics_store_#{name}").to_s.strip
      end

      def setting(name)
        self.class.setting(name)
      end

      def site_url
        Discourse.base_url
      end

      def return_url(provider)
        "#{site_url}/cosmetics-store/payments/#{payment.token}/return?provider=#{provider}"
      end

      def callback_url(provider)
        "#{site_url}/cosmetics-store/callbacks/#{provider}"
      end

      def webhook_url(provider)
        "#{site_url}/cosmetics-store/webhooks/#{provider}"
      end

      def amount_decimal
        format("%.2f", BigDecimal(payment.amount_minor.to_s) / 100)
      end

      def user_email
        user&.email.to_s.strip.downcase
      end

      def buyer_name
        value = billing[:name].presence || user&.name.presence || user&.username
        value.to_s.strip[0, 100]
      end

      def secure_compare(expected, supplied)
        expected = expected.to_s
        supplied = supplied.to_s
        return false if expected.blank? || supplied.blank?

        ActiveSupport::SecurityUtils.secure_compare(
          Digest::SHA256.hexdigest(expected),
          Digest::SHA256.hexdigest(supplied),
        )
      end

      def require_billing!(*fields)
        missing = fields.select { |field| billing[field].to_s.strip.blank? }
        raise Error, "Eksik fatura bilgisi: #{missing.join(', ')}" if missing.present?
      end
    end

    class Stripe < Base
      API = "https://api.stripe.com/v1"

      def self.configured?
        SiteSetting.discourse_cosmetics_store_stripe_enabled &&
          setting("stripe_secret_key").present? &&
          setting("stripe_webhook_secret").present?
      end

      def create_checkout
        response = PaymentHttp.form(
          method: :post,
          url: "#{API}/checkout/sessions",
          headers: { "Authorization" => "Bearer #{setting('stripe_secret_key')}" },
          form: {
            "mode" => "payment",
            "client_reference_id" => payment.token,
            "success_url" => "#{return_url('stripe')}&session_id={CHECKOUT_SESSION_ID}",
            "cancel_url" => "#{site_url}/store?payment=cancelled",
            "line_items[0][quantity]" => "1",
            "line_items[0][price_data][currency]" => payment.currency.downcase,
            "line_items[0][price_data][unit_amount]" => payment.amount_minor,
            "line_items[0][price_data][product_data][name]" => payment.orb_package.name,
            "line_items[0][price_data][product_data][description]" =>
              "#{payment.orb_amount} #{SiteSetting.discourse_cosmetics_store_currency_name}",
            "metadata[store_payment_token]" => payment.token,
            "payment_intent_data[metadata][store_payment_token]" => payment.token,
          },
        )
        raise Error, "Stripe ödeme oturumu oluşturulamadı" if response["id"].blank? || response["url"].blank?

        Checkout.new(provider_payment_id: response["id"], checkout_url: response["url"], metadata: {})
      end

      def self.verify_webhook!(raw_body, signature_header)
        pairs = signature_header.to_s.split(",").filter_map { |part| part.split("=", 2) if part.include?("=") }
        timestamp = (pairs.find { |key, _value| key == "t" }&.last || 0).to_i
        signatures = pairs.filter_map { |key, value| value if key == "v1" }
        raise VerificationError, "Stripe zaman damgası geçersiz" if timestamp.zero? || (Time.now.to_i - timestamp).abs > 300

        expected = OpenSSL::HMAC.hexdigest("SHA256", setting("stripe_webhook_secret"), "#{timestamp}.#{raw_body}")
        verifier = new
        unless signatures.any? { |supplied| verifier.secure_compare(expected, supplied) }
          raise VerificationError, "Stripe imzası geçersiz"
        end

        JSON.parse(raw_body)
      rescue JSON::ParserError
        raise VerificationError, "Stripe bildirimi geçersiz"
      end

      def self.retrieve_session(session_id)
        PaymentHttp.json(
          method: :get,
          url: "#{API}/checkout/sessions/#{URI.encode_www_form_component(session_id)}",
          headers: { "Authorization" => "Bearer #{setting('stripe_secret_key')}" },
        )
      end
    end

    class Paypal < Base
      def self.configured?
        SiteSetting.discourse_cosmetics_store_paypal_enabled &&
          setting("paypal_client_id").present? &&
          setting("paypal_client_secret").present? &&
          setting("paypal_webhook_id").present?
      end

      def self.base_url
        SiteSetting.discourse_cosmetics_store_paypal_sandbox ?
          "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com"
      end

      def self.access_token
        basic = Base64.strict_encode64("#{setting('paypal_client_id')}:#{setting('paypal_client_secret')}")
        response = PaymentHttp.form(
          method: :post,
          url: "#{base_url}/v1/oauth2/token",
          headers: { "Authorization" => "Basic #{basic}" },
          form: { grant_type: "client_credentials" },
        )
        response.fetch("access_token")
      rescue KeyError
        raise Error, "PayPal erişim belirteci alınamadı"
      end

      def create_checkout
        response = PaymentHttp.json(
          method: :post,
          url: "#{self.class.base_url}/v2/checkout/orders",
          headers: {
            "Authorization" => "Bearer #{self.class.access_token}",
            "PayPal-Request-Id" => "create-#{payment.token}",
          },
          body: {
            intent: "CAPTURE",
            purchase_units: [
              {
                custom_id: payment.token,
                description: "#{payment.orb_amount} #{SiteSetting.discourse_cosmetics_store_currency_name}",
                amount: { currency_code: payment.currency, value: amount_decimal },
              },
            ],
            payment_source: {
              paypal: {
                experience_context: {
                  brand_name: SiteSetting.title,
                  user_action: "PAY_NOW",
                  return_url: return_url("paypal"),
                  cancel_url: "#{site_url}/store?payment=cancelled",
                },
              },
            },
          },
        )
        approval = Array(response["links"]).find { |link| link["rel"] == "payer-action" || link["rel"] == "approve" }
        raise Error, "PayPal onay bağlantısı oluşturulamadı" if response["id"].blank? || approval&.dig("href").blank?

        Checkout.new(provider_payment_id: response["id"], checkout_url: approval["href"], metadata: {})
      end

      def self.capture(order_id, idempotency_key)
        PaymentHttp.json(
          method: :post,
          url: "#{base_url}/v2/checkout/orders/#{URI.encode_www_form_component(order_id)}/capture",
          headers: {
            "Authorization" => "Bearer #{access_token}",
            "PayPal-Request-Id" => "capture-#{idempotency_key}",
          },
          body: {},
        )
      end

      def self.verify_webhook!(raw_body, headers)
        event = JSON.parse(raw_body)
        response = PaymentHttp.json(
          method: :post,
          url: "#{base_url}/v1/notifications/verify-webhook-signature",
          headers: { "Authorization" => "Bearer #{access_token}" },
          body: {
            auth_algo: headers["PAYPAL-AUTH-ALGO"],
            cert_url: headers["PAYPAL-CERT-URL"],
            transmission_id: headers["PAYPAL-TRANSMISSION-ID"],
            transmission_sig: headers["PAYPAL-TRANSMISSION-SIG"],
            transmission_time: headers["PAYPAL-TRANSMISSION-TIME"],
            webhook_id: setting("paypal_webhook_id"),
            webhook_event: event,
          },
        )
        raise VerificationError, "PayPal imzası geçersiz" unless response["verification_status"] == "SUCCESS"

        event
      rescue JSON::ParserError
        raise VerificationError, "PayPal bildirimi geçersiz"
      end
    end

    class Paytr < Base
      API = "https://www.paytr.com/odeme/api/get-token"

      def self.configured?
        SiteSetting.discourse_cosmetics_store_paytr_enabled &&
          setting("paytr_merchant_id").present? &&
          setting("paytr_merchant_key").present? &&
          setting("paytr_merchant_salt").present?
      end

      def create_checkout
        require_billing!(:name, :address, :phone)
        merchant_oid = "DCS#{payment.token}"
        currency = payment.currency == "TRY" ? "TL" : payment.currency
        test_mode = SiteSetting.discourse_cosmetics_store_paytr_test_mode ? "1" : "0"
        basket = Base64.strict_encode64(JSON.generate([[payment.orb_package.name, amount_decimal, 1]]))
        ip = request_context&.remote_ip.to_s
        fields = {
          merchant_id: setting("paytr_merchant_id"),
          user_ip: ip,
          merchant_oid: merchant_oid,
          email: user_email,
          payment_amount: payment.amount_minor,
          user_basket: basket,
          no_installment: "1",
          max_installment: "0",
          currency: currency,
          test_mode: test_mode,
          user_name: buyer_name,
          user_address: billing[:address].to_s.strip[0, 400],
          user_phone: billing[:phone].to_s.strip[0, 30],
          merchant_ok_url: return_url("paytr"),
          merchant_fail_url: "#{site_url}/store?payment=failed",
          timeout_limit: "30",
          debug_on: "0",
          lang: "tr",
        }
        source = %i[merchant_id user_ip merchant_oid email payment_amount user_basket no_installment max_installment currency test_mode].map { |key| fields[key] }.join
        fields[:paytr_token] = Base64.strict_encode64(
          OpenSSL::HMAC.digest("SHA256", setting("paytr_merchant_key"), "#{source}#{setting('paytr_merchant_salt')}")
        )
        response = PaymentHttp.form(method: :post, url: API, form: fields)
        raise Error, response["reason"].presence || "PayTR ödeme oturumu oluşturulamadı" unless response["status"] == "success"

        Checkout.new(
          provider_payment_id: merchant_oid,
          checkout_url: "https://www.paytr.com/odeme/guvenli/#{response.fetch('token')}",
          metadata: {},
        )
      end

      def self.verify_callback!(params)
        source = "#{params['merchant_oid']}#{setting('paytr_merchant_salt')}#{params['status']}#{params['total_amount']}"
        expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", setting("paytr_merchant_key"), source))
        raise VerificationError, "PayTR imzası geçersiz" unless new.secure_compare(expected, params["hash"])

        params
      end
    end

    class Iyzico < Base
      INITIALIZE_PATH = "/payment/iyzipos/checkoutform/initialize/auth/ecom"
      RETRIEVE_PATH = "/payment/iyzipos/checkoutform/auth/ecom/detail"

      def self.configured?
        SiteSetting.discourse_cosmetics_store_iyzico_enabled &&
          setting("iyzico_api_key").present? &&
          setting("iyzico_secret_key").present?
      end

      def self.base_url
        SiteSetting.discourse_cosmetics_store_iyzico_sandbox ?
          "https://sandbox-api.iyzipay.com" : "https://api.iyzipay.com"
      end

      def create_checkout
        require_billing!(:name, :address, :phone, :city, :country, :identity_number)
        names = buyer_name.split(/\s+/, 2)
        address = {
          contactName: buyer_name,
          city: billing[:city].to_s.strip[0, 50],
          country: billing[:country].to_s.strip[0, 50],
          address: billing[:address].to_s.strip[0, 400],
          zipCode: billing[:zip_code].to_s.strip[0, 20],
        }
        payload = {
          locale: "tr",
          conversationId: payment.token,
          price: amount_decimal,
          paidPrice: amount_decimal,
          currency: payment.currency,
          basketId: payment.token,
          paymentGroup: "PRODUCT",
          callbackUrl: callback_url("iyzico"),
          enabledInstallments: [1],
          buyer: {
            id: user.id.to_s,
            name: names.first,
            surname: names.second.presence || "Üye",
            gsmNumber: billing[:phone].to_s.strip[0, 30],
            email: user_email,
            identityNumber: billing[:identity_number].to_s.gsub(/\D/, "")[0, 20],
            registrationAddress: address[:address],
            ip: request_context&.remote_ip.to_s,
            city: address[:city],
            country: address[:country],
            zipCode: address[:zipCode],
          },
          shippingAddress: address,
          billingAddress: address,
          basketItems: [
            {
              id: "orb-package-#{payment.orb_package_id}",
              name: payment.orb_package.name,
              category1: "Dijital Kozmetik",
              itemType: "VIRTUAL",
              price: amount_decimal,
            },
          ],
        }
        response = self.class.signed_post(INITIALIZE_PATH, payload)
        unless response["status"] == "success" && response["token"].present? && response["paymentPageUrl"].present?
          raise Error, response["errorMessage"].presence || "iyzico ödeme formu oluşturulamadı"
        end

        Checkout.new(
          provider_payment_id: response["token"],
          checkout_url: response["paymentPageUrl"],
          metadata: { "iyzico_token" => response["token"] },
        )
      end

      def self.retrieve(token, conversation_id)
        signed_post(
          RETRIEVE_PATH,
          { locale: "tr", conversationId: conversation_id, token: token },
        )
      end

      def self.signed_post(path, payload)
        body = JSON.generate(payload)
        random_key = "#{Time.now.to_i}#{SecureRandom.hex(12)}"
        signature = OpenSSL::HMAC.hexdigest("SHA256", setting("iyzico_secret_key"), "#{random_key}#{path}#{body}")
        auth = Base64.strict_encode64("apiKey:#{setting('iyzico_api_key')}&randomKey:#{random_key}&signature:#{signature}")
        raw = PaymentHttp.request(
          method: :post,
          url: "#{base_url}#{path}",
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "Authorization" => "IYZWSv2 #{auth}",
            "x-iyzi-rnd" => random_key,
          },
          body: body,
        )
        JSON.parse(raw)
      rescue JSON::ParserError
        raise Error, "iyzico geçersiz yanıt verdi"
      end

      def self.valid_response_signature?(response)
        supplied = response["signature"].to_s
        return false if supplied.blank?

        ordered = %w[paymentStatus paymentId currency basketId conversationId paidPrice price token]
        values = ordered.filter_map do |key|
          next unless response.key?(key)
          value = response[key].to_s
          value = value.sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1") if %w[price paidPrice].include?(key)
          value
        end
        expected = OpenSSL::HMAC.hexdigest("SHA256", setting("iyzico_secret_key"), values.join(":"))
        new.secure_compare(expected, supplied)
      end
    end

    class Shopier < Base
      def self.configured?
        SiteSetting.discourse_cosmetics_store_shopier_enabled && setting("shopier_webhook_token").present?
      end

      def create_checkout
        url = payment.orb_package.shopier_checkout_url
        product_id = payment.orb_package.shopier_product_id
        raise ConfigurationError, "Bu Orb paketi için Shopier ürün bağlantısı ve ürün kimliği gerekli" if url.blank? || product_id.blank?

        Checkout.new(
          provider_payment_id: nil,
          checkout_url: url,
          metadata: { "shopier_product_id" => product_id },
        )
      end

      def self.verify_webhook!(raw_body, signature)
        expected_raw = OpenSSL::HMAC.digest("SHA256", setting("shopier_webhook_token"), raw_body)
        supplied = signature.to_s.sub(/\Asha256=/i, "")
        candidates = [expected_raw.unpack1("H*"), Base64.strict_encode64(expected_raw)]
        raise VerificationError, "Shopier imzası geçersiz" unless candidates.any? { |value| new.secure_compare(value, supplied) }

        JSON.parse(raw_body)
      rescue JSON::ParserError
        raise VerificationError, "Shopier bildirimi geçersiz"
      end
    end

    class Shipy < Base
      API = "https://api.shipy.dev/pay/credit_card"

      def self.configured?
        SiteSetting.discourse_cosmetics_store_shipy_enabled && setting("shipy_api_key").present?
      end

      def create_checkout
        require_billing!(:name, :address, :phone)
        response = PaymentHttp.form(
          method: :post,
          url: API,
          form: {
            apiKey: setting("shipy_api_key"),
            returnID: payment.token,
            amount: amount_decimal,
            currency: payment.currency,
            usrIp: request_context&.remote_ip.to_s,
            usrName: buyer_name,
            usrAddress: billing[:address].to_s.strip[0, 400],
            usrPhone: billing[:phone].to_s.strip[0, 30],
            usrEmail: user_email,
            pageLang: "TR",
            mailLang: "TR",
            installment: "0",
          },
        )
        url = response["link"].presence || response["url"].presence
        raise Error, response["message"].presence || "Shipy ödeme bağlantısı oluşturulamadı" if url.blank?

        Checkout.new(provider_payment_id: response["paymentID"], checkout_url: url, metadata: {})
      end

      def self.verify_callback!(params)
        source = %w[paymentID returnID paymentType paymentAmount paymentCurrency].map { |key| params[key].to_s }.join
        expected = Base64.strict_encode64(Digest::SHA1.digest("#{source}#{setting('shipy_api_key')}"))
        raise VerificationError, "Shipy imzası geçersiz" unless new.secure_compare(expected, params["paymentHash"])

        params
      end
    end

    PROVIDERS = {
      "stripe" => Stripe,
      "paypal" => Paypal,
      "paytr" => Paytr,
      "iyzico" => Iyzico,
      "shopier" => Shopier,
      "shipy" => Shipy,
    }.freeze

    def self.fetch(name)
      PROVIDERS.fetch(name.to_s) { raise ConfigurationError, "Desteklenmeyen ödeme sağlayıcısı" }
    end

    def self.validate_checkout_url!(provider, value)
      uri = URI.parse(value.to_s)
      host = uri.host.to_s.downcase
      allowed = CHECKOUT_HOST_SUFFIXES.fetch(provider.to_s)
      valid =
        uri.is_a?(URI::HTTPS) &&
          uri.userinfo.blank? &&
          allowed.any? { |suffix| host == suffix || host.end_with?(".#{suffix}") }
      raise VerificationError, "Ödeme yönlendirme adresi sağlayıcı alan adıyla eşleşmiyor" unless valid

      true
    rescue URI::InvalidURIError
      raise VerificationError, "Ödeme yönlendirme adresi geçersiz"
    end

    def self.enabled
      return [] unless SiteSetting.discourse_cosmetics_store_payments_enabled

      PROVIDERS.filter_map do |key, klass|
        next unless klass.configured?

        {
          id: key,
          label: PROVIDER_LABELS.fetch(key),
          requires_billing: %w[paytr iyzico shipy].include?(key),
          requires_identity: key == "iyzico",
        }
      end
    end

    def self.configuration_status
      PROVIDERS.map do |key, klass|
        {
          id: key,
          label: PROVIDER_LABELS.fetch(key),
          enabled: klass.configured?,
          webhook_url: %w[stripe paypal shopier].include?(key) ? "#{Discourse.base_url}/cosmetics-store/webhooks/#{key}" : nil,
          callback_url: %w[paytr iyzico shipy].include?(key) ? "#{Discourse.base_url}/cosmetics-store/callbacks/#{key}" : nil,
        }
      end
    end
  end
end
