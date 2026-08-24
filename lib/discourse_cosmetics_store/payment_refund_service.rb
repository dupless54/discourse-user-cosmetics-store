# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentRefundService
    class Invalid < StandardError; end

    COMPLETED_STATUSES = %w[completed complete success successful succeeded refunded done].freeze
    PROCESSING_STATUSES = %w[processing pending initiated in_progress].freeze
    FAILED_STATUSES = %w[failed rejected cancelled canceled error].freeze

    attr_reader :payment, :refund

    def self.record!(payment:, provider_refund_id:, amount_minor:, currency:, status:,
                     source: "webhook", metadata: {}, created_by: nil, completed_at: nil)
      new(
        payment: payment,
        provider_refund_id: provider_refund_id,
        amount_minor: amount_minor,
        currency: currency,
        status: status,
        source: source,
        metadata: metadata,
        created_by: created_by,
        completed_at: completed_at,
      ).call
    end

    def initialize(payment:, provider_refund_id:, amount_minor:, currency:, status:,
                   source:, metadata:, created_by:, completed_at:)
      @payment = payment
      @provider_refund_id = provider_refund_id.to_s.strip
      @amount_minor = amount_minor.to_i
      @currency = currency.to_s.upcase == "TL" ? "TRY" : currency.to_s.upcase
      @status = normalize_status(status)
      @source = source.to_s
      @metadata = metadata.is_a?(Hash) ? metadata.deep_stringify_keys : {}
      @created_by = created_by
      @completed_at = completed_at || Time.zone.now
    end

    def call
      validate_base_input!

      Payment.transaction do
        payment.lock!
        @refund = find_or_initialize_refund
        validate_existing_refund!
        return refund if refund.completed?
        unless payment.refundable?
          raise Invalid, "Yalnızca tamamlanmış ve henüz tamamen iade edilmemiş ödemeler iade edilebilir"
        end

        refund.assign_attributes(
          status: @status == "completed" ? "processing" : @status,
          source: @source,
          metadata: refund.metadata.to_h.merge(@metadata),
          created_by: @created_by || refund.created_by,
        )
        refund.save!

        complete_refund! if @status == "completed"
        refund
      end
    end

    private

    def normalize_status(value)
      normalized = value.to_s.strip.downcase
      return "completed" if COMPLETED_STATUSES.include?(normalized)
      return "processing" if PROCESSING_STATUSES.include?(normalized)
      return "failed" if FAILED_STATUSES.include?(normalized)

      "requested"
    end

    def validate_base_input!
      raise Invalid, "İade sağlayıcısı ödeme ile eşleşmiyor" unless payment.provider == "shopier"
      if @provider_refund_id.blank? || @provider_refund_id.length > 190
        raise Invalid, "Shopier iade kimliği geçersiz"
      end
      raise Invalid, "İade tutarı geçersiz" unless @amount_minor.positive?
      raise Invalid, "İade tutarı ödeme tutarını aşamaz" if @amount_minor > payment.amount_minor.to_i
      raise Invalid, "İade para birimi eşleşmiyor" unless @currency == payment.currency
      raise Invalid, "İade kaynağı geçersiz" unless PaymentRefund::SOURCES.include?(@source)
    end

    def find_or_initialize_refund
      PaymentRefund.find_or_initialize_by(
        provider: payment.provider,
        provider_refund_id: @provider_refund_id,
      ) do |row|
        row.payment = payment
        row.amount_minor = @amount_minor
        row.currency = @currency
        row.status = "requested"
        row.source = @source
        row.metadata = {}
        row.created_by = @created_by
      end
    end

    def validate_existing_refund!
      return unless refund.persisted?

      unless refund.payment_id == payment.id &&
               refund.amount_minor.to_i == @amount_minor &&
               refund.currency == @currency
        raise Invalid, "Shopier iade bilgileri daha önceki kayıtla eşleşmiyor"
      end
    end

    def complete_refund!
      target_refunded_minor = payment.refunded_amount_minor.to_i + refund.amount_minor.to_i
      if target_refunded_minor > payment.amount_minor.to_i
        raise Invalid, "Toplam iade ödeme tutarını aşamaz"
      end

      target_refunded_orbs =
        if target_refunded_minor == payment.amount_minor.to_i
          payment.orb_amount.to_i
        else
          numerator = payment.orb_amount.to_i * target_refunded_minor
          (numerator + payment.amount_minor.to_i / 2) / payment.amount_minor.to_i
        end
      orb_delta = target_refunded_orbs - payment.refunded_orb_amount.to_i
      raise Invalid, "İade edilen Orb toplamı geçersiz" if orb_delta.negative?

      if orb_delta.positive?
        WalletService.refund_debit!(
          user: payment.user,
          amount: orb_delta,
          idempotency_key: "payment-refund:#{refund.id}",
          reason: "#{payment.orb_package.name} para iadesi",
          reference_type: "DiscourseCosmeticsStore::PaymentRefund",
          reference_id: refund.id,
          created_by: @created_by,
        )
      end

      refund.update!(
        status: "completed",
        orb_amount: orb_delta,
        completed_at: @completed_at,
      )
      payment.update!(
        status:
          target_refunded_minor == payment.amount_minor.to_i ?
            "refunded" : "partially_refunded",
        refunded_amount_minor: target_refunded_minor,
        refunded_orb_amount: target_refunded_orbs,
        refunded_at: @completed_at,
      )
    end
  end
end
