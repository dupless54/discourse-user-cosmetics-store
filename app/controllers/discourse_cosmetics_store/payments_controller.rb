# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentsController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_store_enabled
    before_action :ensure_logged_in, except: :return_from_provider

    def create
      package = OrbPackage.available.find(params[:orb_package_id])
      service = PaymentService.new(
        user: current_user,
        orb_package: package,
        provider: params[:provider],
        request_context: request,
        billing: billing_params,
      ).call

      render json: serialize_payment(service.payment).merge(checkout_url: service.payment.checkout_url)
    rescue PaymentService::Disabled, PaymentService::Unavailable, PaymentProviders::ConfigurationError => error
      render_error(error.message.presence || I18n.t("discourse_cosmetics_store.errors.payment_unavailable"), :unprocessable_entity)
    rescue PaymentProviders::Error, PaymentHttp::Error => error
      render_error(error.message, :unprocessable_entity)
    end

    def status
      payment = Payment.find_by!(token: params[:payment_token], user_id: current_user.id)
      render json: serialize_payment(payment)
    end

    def return_from_provider
      payment = Payment.find_by!(token: params[:payment_token])
      provider = params[:provider].to_s
      raise Discourse::InvalidAccess unless payment.provider == provider

      finalize_browser_return(payment, provider) unless payment.complete?
      redirect_to "#{Discourse.base_path}/store?payment=#{payment.reload.status}", allow_other_host: false
    rescue StandardError => error
      Rails.logger.warn("[#{DiscourseCosmeticsStore::PLUGIN_NAME}] payment return failed: #{error.class}: #{error.message}")
      redirect_to "#{Discourse.base_path}/store?payment=pending", allow_other_host: false
    end

    private

    def ensure_store_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_enabled
    end

    def billing_params
      params.permit(:name, :address, :phone, :city, :country, :zip_code, :identity_number).to_h
    end

    def finalize_browser_return(payment, provider)
      case provider
      when "stripe"
        session = PaymentProviders::Stripe.retrieve_session(payment.provider_payment_id)
        return unless session["payment_status"] == "paid"

        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: session["id"],
          amount_minor: session["amount_total"],
          currency: session["currency"],
        )
      when "paypal"
        response = PaymentProviders::Paypal.capture(payment.provider_payment_id, payment.token)
        return unless response["status"] == "COMPLETED"

        unit = Array(response["purchase_units"]).first || {}
        amount = unit.dig("payments", "captures", 0, "amount") || unit["amount"] || {}
        capture_id = unit.dig("payments", "captures", 0, "id")
        payment.update_columns(metadata: payment.metadata.merge("paypal_capture_id" => capture_id)) if capture_id.present?
        PaymentFulfillmentService.complete!(
          payment: payment,
          provider_payment_id: payment.provider_payment_id,
          amount_minor: decimal_to_minor(amount["value"]),
          currency: amount["currency_code"],
        )
      end
    end

    def decimal_to_minor(value)
      (BigDecimal(value.to_s) * 100).round(0).to_i
    end

    def serialize_payment(payment)
      {
        token: payment.token,
        provider: payment.provider,
        status: payment.status,
        orb_amount: payment.orb_amount,
        amount_minor: payment.amount_minor,
        currency: payment.currency,
        completed_at: payment.completed_at&.iso8601,
        failure_message: payment.failure_message,
      }
    end

    def render_error(message, status)
      render json: { errors: [message] }, status: status
    end
  end
end
