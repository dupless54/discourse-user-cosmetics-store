# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentCallbacksController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    skip_before_action :verify_authenticity_token
    before_action :ensure_payments_enabled

    MAX_WEBHOOK_BYTES = 256.kilobytes

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
    rescue PaymentProviders::VerificationError
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
      else
        raise Discourse::NotFound
      end
    rescue PaymentProviders::VerificationError
      head :unauthorized
    rescue StandardError => error
      log_failure(provider, error)
      head :unprocessable_entity
    end

    private

    def ensure_payments_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_payments_enabled
    end

    def raw_body!
      raw = request.raw_post.to_s
      raise PaymentProviders::VerificationError, "Bildirim gövdesi boş" if raw.blank?
      raise PaymentProviders::VerificationError, "Bildirim gövdesi çok büyük" if raw.bytesize > MAX_WEBHOOK_BYTES

      raw
    end

    def handle_stripe(raw)
      event = PaymentProviders::Stripe.verify_webhook!(raw, request.headers["Stripe-Signature"])
      return unless %w[checkout.session.completed checkout.session.async_payment_succeeded].include?(event["type"])

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
      order = payload["data"] || payload["order"] || payload
      status = (order["paymentStatus"] || order["payment_status"] || order["status"]).to_s.downcase
      return unless %w[paid completed success].include?(status)

      order_id = (order["id"] || order["orderId"] || order["order_id"]).to_s
      raise PaymentProviders::VerificationError, "Shopier sipariş kimliği eksik" if order_id.blank?

      product_ids =
        Array(order["lineItems"] || order["line_items"]).map do |row|
          (row["productId"] || row["product_id"]).to_s
        end
      product_ids << (order["productId"] || order["product_id"]).to_s
      product_ids.reject!(&:blank?)
      email = order.dig("shippingInfo", "email") || order.dig("billingInfo", "email") || order["email"]
      package = OrbPackage.ordered.find { |row| product_ids.include?(row.shopier_product_id.to_s) }
      raise ActiveRecord::RecordNotFound unless package

      user = User.activated.with_primary_email(email.to_s.strip.downcase).first
      raise ActiveRecord::RecordNotFound unless user

      amount = order.dig("totals", "total") || order["total"] || order["amount"]
      currency = (order["currency"] || order.dig("totals", "currency")).to_s.upcase
      currency = "TRY" if currency == "TL"
      amount_minor = decimal_to_minor(amount)
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

      PaymentEventService.process!(provider: "shopier", external_id: order_id, raw_body: raw, payment: payment) do
        payment.update!(provider_payment_id: order_id)
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: order_id,
          amount_minor: amount_minor,
          currency: currency,
        )
      end
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
      (BigDecimal(value.to_s) * 100).round(0).to_i
    end

    def log_failure(provider, error)
      Rails.logger.warn(
        "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] #{provider} payment callback failed: " \
          "#{error.class}: #{error.message}",
      )
    end
  end
end
