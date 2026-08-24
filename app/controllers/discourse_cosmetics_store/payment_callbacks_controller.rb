# frozen_string_literal: true

require "digest"

module ::DiscourseCosmeticsStore
  class PaymentCallbacksController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    skip_before_action :verify_authenticity_token
    before_action :ensure_payments_enabled, unless: :shopier_callback?

    MAX_WEBHOOK_BYTES = 256.kilobytes
    SHOPIER_REFUND_EVENTS = %w[refund.requested refund.updated].freeze

    def webhook
      provider = params[:provider].to_s
      raw = raw_body!
      case provider
      when "stripe" then handle_stripe(raw)
      when "paypal" then handle_paypal(raw)
      when "shopier" then handle_shopier(raw)
      else raise Discourse::NotFound
      end
      head :ok
    rescue PaymentProviders::VerificationError => error
      log_failure(provider, error)
      head :unauthorized
    rescue StandardError => error
      log_failure(provider, error)
      head :unprocessable_entity
    end

    def callback
      provider = params[:provider].to_s
      case provider
      when "paytr"
        handle_paytr
        render plain: "OK", content_type: "text/plain"
      when "iyzico"
        payment = handle_iyzico
        redirect_to "#{Discourse.base_path}/store?payment=#{payment.status}", allow_other_host: false
      when "shipy"
        handle_shipy
        render plain: "OK", content_type: "text/plain"
      when "shopier-osb"
        handle_shopier_osb
        render plain: "success", content_type: "text/plain"
      else
        raise Discourse::NotFound
      end
    rescue PaymentProviders::VerificationError => error
      log_failure(provider, error)
      head :unauthorized
    rescue StandardError => error
      log_failure(provider, error)
      head :unprocessable_entity
    end

    private

    def ensure_payments_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_payments_enabled
    end

    def shopier_callback?
      (action_name == "callback" && params[:provider].to_s == "shopier-osb") ||
        (action_name == "webhook" && params[:provider].to_s == "shopier")
    end

    def raw_body!
      raw = request.raw_post.to_s
      raise PaymentProviders::VerificationError, "Bildirim gövdesi boş" if raw.blank?
      raise PaymentProviders::VerificationError, "Bildirim gövdesi çok büyük" if raw.bytesize > MAX_WEBHOOK_BYTES

      raw
    end

    def handle_stripe(raw)
      event = PaymentProviders::Stripe.verify_webhook!(raw, request.headers["Stripe-Signature"])
      return if %w[checkout.session.completed checkout.session.async_payment_succeeded].exclude?(event["type"])

      session = event.dig("data", "object") || {}
      token = session["client_reference_id"].presence || session.dig("metadata", "store_payment_token")
      payment = Payment.find_by!(token: token, provider: "stripe")
      PaymentEventService.process!(provider: "stripe", external_id: event.fetch("id"), raw_body: raw, payment: payment) do
        raise PaymentFulfillmentService::Mismatch, "Stripe ödemesi tamamlanmamış" unless session["payment_status"] == "paid"
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: session["id"],
          amount_minor: session["amount_total"],
          currency: session["currency"],
        )
      end
    end

    def handle_paypal(raw)
      headers = %w[
        PAYPAL-AUTH-ALGO
        PAYPAL-CERT-URL
        PAYPAL-TRANSMISSION-ID
        PAYPAL-TRANSMISSION-SIG
        PAYPAL-TRANSMISSION-TIME
      ].to_h { |name| [name, request.headers[name]] }
      event = PaymentProviders::Paypal.verify_webhook!(raw, headers)
      return unless event["event_type"] == "CHECKOUT.ORDER.APPROVED"

      order_id = event.dig("resource", "id")
      payment = Payment.find_by!(provider: "paypal", provider_payment_id: order_id)
      PaymentEventService.process!(provider: "paypal", external_id: event.fetch("id"), raw_body: raw, payment: payment) do
        response = PaymentProviders::Paypal.capture(order_id, payment.token)
        raise PaymentFulfillmentService::Mismatch, "PayPal capture tamamlanmadı" unless response["status"] == "COMPLETED"
        unit = Array(response["purchase_units"]).first || {}
        amount = unit.dig("payments", "captures", 0, "amount") || {}
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: order_id,
          amount_minor: decimal_to_minor(amount["value"]),
          currency: amount["currency_code"],
        )
      end
    end

    def handle_shopier(raw)
      payload = PaymentProviders::Shopier.verify_webhook!(raw, request.headers["Shopier-Signature"])
      event_type = shopier_event_type(payload)
      if SHOPIER_REFUND_EVENTS.include?(event_type) || shopier_refund_payload?(payload)
        refund_event = SHOPIER_REFUND_EVENTS.include?(event_type) ? event_type : "refund.updated"
        return handle_shopier_refund(payload, raw, refund_event)
      end
      return if event_type.present? && !event_type.start_with?("order.")

      unless SiteSetting.discourse_cosmetics_store_payments_enabled &&
               SiteSetting.discourse_cosmetics_store_shopier_enabled
        raise PaymentProviders::ConfigurationError, "Shopier canlı ödemeleri kapalı"
      end

      order = payload["data"] || payload["order"] || payload
      status = (order["paymentStatus"] || order["payment_status"] || order["status"]).to_s.downcase
      return if %w[paid completed success].exclude?(status)

      order_id = (order["id"] || order["orderId"] || order["order_id"]).to_s
      raise PaymentProviders::VerificationError, "Shopier sipariş kimliği eksik" if order_id.blank?

      product_ids =
        Array(order["lineItems"] || order["line_items"]).map do |row|
          (row["productId"] || row["product_id"]).to_s
        end
      product_ids << (order["productId"] || order["product_id"]).to_s
      product_ids.reject!(&:blank?)
      email = order.dig("shippingInfo", "email") || order.dig("billingInfo", "email") || order["email"]
      amount = order.dig("totals", "total") || order["total"] || order["amount"]
      currency = (order["currency"] || order.dig("totals", "currency")).to_s.upcase
      currency = "TRY" if currency == "TL"
      amount_minor = decimal_to_minor(amount)
      package = find_shopier_package!(product_ids)
      payment = find_shopier_payment!(email, package, amount_minor, currency, order_id)

      complete_shopier_payment!(payment, order_id, amount_minor, currency, raw)
    end

    def handle_shopier_refund(payload, raw, event_type)
      refund = payload["data"] || payload["refund"] || payload
      unless refund.is_a?(Hash)
        raise PaymentProviders::VerificationError, "Shopier iade bildirimi geçersiz"
      end
      refund = refund["refund"] if refund["refund"].is_a?(Hash)

      refund_order = refund["order"].is_a?(Hash) ? refund["order"] : {}

      refund_id =
        first_present(
          refund["id"],
          refund["refundId"],
          refund["refund_id"],
          payload["refundId"],
          payload["refund_id"],
        ).to_s
      order_id =
        first_present(
          refund["orderId"],
          refund["order_id"],
          refund_order["id"],
          refund_order["orderId"],
          refund_order["order_id"],
          payload["orderId"],
          payload["order_id"],
        ).to_s
      raise PaymentProviders::VerificationError, "Shopier iade kimliği eksik" if refund_id.blank?
      raise PaymentProviders::VerificationError, "Shopier iade sipariş kimliği eksik" if order_id.blank?

      payment = Payment.find_by!(provider: "shopier", provider_payment_id: order_id)
      amount_minor, currency = shopier_refund_amount(refund, payload)
      status =
        first_present(
          refund["status"],
          refund["refundStatus"],
          refund["refund_status"],
          payload["status"],
        )
      status = event_type == "refund.requested" ? "requested" : status
      raise PaymentProviders::VerificationError, "Shopier iade durumu eksik" if status.blank?

      delivery_id =
        first_present(
          request.headers["Shopier-Webhook-Id"],
          payload["webhookId"],
          payload["webhook_id"],
          payload["eventId"],
          payload["event_id"],
        )
      event_digest = Digest::SHA256.hexdigest("#{refund_id}:#{status}:#{raw}")
      event_id = "refund:#{event_digest}"

      PaymentEventService.process!(
        provider: "shopier",
        external_id: event_id,
        raw_body: raw,
        payment: payment,
      ) do
        PaymentRefundService.record!(
          payment: payment,
          provider_refund_id: refund_id,
          amount_minor: amount_minor,
          currency: currency,
          status: status,
          source: "webhook",
          metadata: {
            "event_type" => event_type,
            "order_id" => order_id,
            "refund_id" => refund_id,
            "status" => status.to_s,
            "webhook_id" => delivery_id.to_s,
          },
        )
      end
    end

    def handle_shopier_osb
      encoded_result = params[:res].to_s
      payload = PaymentProviders::Shopier.verify_osb!(encoded_result, params[:hash])
      return if PaymentProviders::Shopier.osb_test?(payload)

      unless SiteSetting.discourse_cosmetics_store_payments_enabled &&
               SiteSetting.discourse_cosmetics_store_shopier_enabled
        raise PaymentProviders::ConfigurationError, "Shopier canlı ödemeleri kapalı"
      end

      order_id = payload["orderid"].to_s.strip
      raise PaymentProviders::VerificationError, "Shopier OSB sipariş kimliği eksik" if order_id.blank?

      product_ids =
        Array(payload["productid"]).flat_map do |value|
          value.to_s.split(/[,;|]/).map(&:strip)
        end
      product_ids.reject!(&:blank?)
      package = find_shopier_package!(product_ids)
      amount_minor = decimal_to_minor(payload["price"])
      currency = PaymentProviders::Shopier.osb_currency(payload["currency"])
      payment =
        find_shopier_payment!(payload["email"], package, amount_minor, currency, order_id)

      complete_shopier_payment!(payment, order_id, amount_minor, currency, encoded_result)
    end

    def handle_paytr
      data = PaymentProviders::Paytr.verify_callback!(params.to_unsafe_h)
      token = data["merchant_oid"].to_s.delete_prefix("DCS")
      payment = Payment.find_by!(token: token, provider: "paytr")
      event_id = "#{data['merchant_oid']}:#{data['status']}:#{data['total_amount']}"
      PaymentEventService.process!(provider: "paytr", external_id: event_id, raw_body: request.raw_post, payment: payment) do
        if data["status"] == "success"
          PaymentFulfillmentService.complete!(
            payment: payment,
            provider_payment_id: data["merchant_oid"],
            amount_minor: data["payment_amount"],
            currency: data["currency"] == "TL" ? "TRY" : data["currency"],
          )
        else
          PaymentFulfillmentService.fail!(
            payment: payment,
            code: data["failed_reason_code"],
            message: data["failed_reason_msg"],
          )
        end
      end
    end

    def handle_iyzico
      token = params[:token].to_s
      payment = Payment.find_by!(provider: "iyzico", provider_payment_id: token)
      response = PaymentProviders::Iyzico.retrieve(token, payment.token)
      raise PaymentProviders::VerificationError, "iyzico yanıt imzası geçersiz" unless PaymentProviders::Iyzico.valid_response_signature?(response)

      external_id = response["paymentId"].presence || "iyzico:#{token}"
      PaymentEventService.process!(provider: "iyzico", external_id: external_id, raw_body: JSON.generate(response), payment: payment) do
        unless response["status"] == "success" && response["paymentStatus"] == "SUCCESS" && response["fraudStatus"].to_i == 1
          PaymentFulfillmentService.fail!(payment: payment, code: response["errorCode"], message: response["errorMessage"] || "Ödeme onaylanmadı")
          next
        end
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: token,
          amount_minor: decimal_to_minor(response["paidPrice"]),
          currency: response["currency"],
        )
      end
      payment.reload
    end

    def handle_shipy
      data = PaymentProviders::Shipy.verify_callback!(params.to_unsafe_h)
      payment = Payment.find_by!(token: data["returnID"], provider: "shipy")
      external_id = data["paymentID"].presence || "shipy:#{payment.token}"
      PaymentEventService.process!(provider: "shipy", external_id: external_id, raw_body: request.raw_post, payment: payment) do
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: data["paymentID"],
          amount_minor: decimal_to_minor(data["paymentAmount"]),
          currency: data["paymentCurrency"],
        )
      end
    end

    def decimal_to_minor(value)
      decimal = BigDecimal(value.to_s.tr(",", "."))
      raise ArgumentError unless decimal.finite?

      minor = decimal * 100
      raise ArgumentError unless minor == minor.to_i

      minor.to_i
    rescue ArgumentError, TypeError
      raise PaymentProviders::VerificationError, "Ödeme tutarı geçersiz"
    end

    def shopier_event_type(payload)
      value =
        first_present(
          request.headers["Shopier-Event"],
          request.headers["X-Shopier-Event"],
          payload["eventType"],
          payload["event_type"],
          payload["eventName"],
          payload["event_name"],
          payload["event"].is_a?(Hash) ? payload.dig("event", "type") : payload["event"],
          payload["type"],
        )
      value.to_s.strip.downcase
    end

    def shopier_refund_amount(refund, payload)
      minor_value =
        first_present(
          refund["amountMinor"],
          refund["amount_minor"],
          refund["refundAmountMinor"],
          refund["refund_amount_minor"],
        )
      amount_value =
        first_present(
          refund["amount"],
          refund["refundAmount"],
          refund["refund_amount"],
          refund["total"],
          payload["amount"],
        )

      currency =
        first_present(
          refund["currency"],
          amount_value.is_a?(Hash) ?
            first_present(
              amount_value["currency"],
              amount_value["currencyCode"],
              amount_value["currency_code"],
            ) :
            nil,
          payload["currency"],
        ).to_s.upcase
      currency = "TRY" if currency == "TL"
      raise PaymentProviders::VerificationError, "Shopier iade para birimi eksik" if currency.blank?

      amount_minor =
        if minor_value.present?
          Integer(minor_value.to_s, 10)
        else
          decimal_value =
            amount_value.is_a?(Hash) ?
              first_present(amount_value["value"], amount_value["amount"], amount_value["total"]) :
              amount_value
          decimal_to_minor(decimal_value)
        end
      raise PaymentProviders::VerificationError, "Shopier iade tutarı geçersiz" unless amount_minor.positive?

      [amount_minor, currency]
    rescue ArgumentError, TypeError
      raise PaymentProviders::VerificationError, "Shopier iade tutarı geçersiz"
    end

    def shopier_refund_payload?(payload)
      candidate = payload["data"] || payload["refund"] || payload
      return false unless candidate.is_a?(Hash)

      candidate = candidate["refund"] if candidate["refund"].is_a?(Hash)
      refund_type = first_present(candidate["type"], candidate["refundType"], candidate["refund_type"])
      %w[full partial].include?(refund_type.to_s.downcase)
    end

    def first_present(*values)
      values.find(&:present?)
    end

    def find_shopier_package!(product_ids)
      normalized_ids = Array(product_ids).map { |value| value.to_s.strip }.reject(&:blank?)
      package =
        OrbPackage.ordered.find do |row|
          row.provider_enabled?("shopier") && normalized_ids.include?(row.shopier_product_id.to_s)
        end
      raise ActiveRecord::RecordNotFound unless package

      package
    end

    def find_shopier_payment!(email, package, amount_minor, currency, order_id)
      normalized_email = email.to_s.strip.downcase
      raise PaymentProviders::VerificationError, "Shopier alıcı e-postası eksik" if normalized_email.blank?

      user = User.activated.with_primary_email(normalized_email).first
      raise ActiveRecord::RecordNotFound unless user

      existing = Payment.find_by(provider: "shopier", provider_payment_id: order_id)
      if existing
        unless existing.user_id == user.id && existing.orb_package_id == package.id &&
                 existing.amount_minor == amount_minor && existing.currency == currency
          raise PaymentFulfillmentService::Mismatch, "Shopier sipariş bilgileri eşleşmiyor"
        end

        return existing
      end

      payment =
        Payment
          .where(
            user_id: user.id,
            orb_package_id: package.id,
            provider: "shopier",
            status: "pending",
            amount_minor: amount_minor,
            currency: currency,
          )
          .recent
          .first
      raise ActiveRecord::RecordNotFound unless payment

      payment
    end

    def complete_shopier_payment!(payment, order_id, amount_minor, currency, raw_body)
      PaymentEventService.process!(
        provider: "shopier",
        external_id: order_id,
        raw_body: raw_body,
        payment: payment,
      ) do
        payment.update!(provider_payment_id: order_id)
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: order_id,
          amount_minor: amount_minor,
          currency: currency,
        )
      end
    end

    def log_failure(provider, error)
      Rails.logger.warn(
        "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] #{provider} payment callback failed: " \
          "#{error.class}: #{error.message}",
      )
    end
  end
end
