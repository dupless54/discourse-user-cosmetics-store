# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PaymentFulfillmentService
    class Mismatch < StandardError; end

    def self.complete!(payment:, provider_payment_id:, amount_minor:, currency:)
      Payment.transaction do
        payment.lock!
        return payment if payment.complete?
        raise Mismatch, "Ödeme artık tamamlanabilir durumda değil" if %w[cancelled expired refunded].include?(payment.status)
        raise Mismatch, "Ödeme tutarı eşleşmiyor" unless payment.amount_minor.to_i == amount_minor.to_i
        raise Mismatch, "Ödeme para birimi eşleşmiyor" unless payment.currency == currency.to_s.upcase

        if provider_payment_id.present? && payment.provider_payment_id.present? &&
             payment.provider_payment_id != provider_payment_id
          raise Mismatch, "Sağlayıcı işlem kimliği eşleşmiyor"
        end

        payment.update!(
          status: "processing",
          provider_payment_id: provider_payment_id.presence || payment.provider_payment_id,
          failure_code: nil,
          failure_message: nil,
        )
        WalletService.credit!(
          user: payment.user,
          amount: payment.orb_amount,
          entry_type: "payment",
          idempotency_key: "payment:#{payment.id}",
          reason: "#{payment.orb_package.name} satın alımı",
          reference_type: "DiscourseCosmeticsStore::Payment",
          reference_id: payment.id,
        )
        payment.update!(status: "completed", completed_at: Time.zone.now)
        payment
      end
    rescue ActiveRecord::RecordNotUnique
      payment.reload
      raise Mismatch, "Ödeme cüzdan hareketi tamamlanamadı" unless payment.complete?

      payment
    end

    def self.fail!(payment:, code:, message:)
      payment.with_lock do
        return payment if payment.complete?

        payment.update!(
          status: "failed",
          failure_code: code.to_s[0, 100],
          failure_message: message.to_s[0, 500],
        )
      end
      payment
    end
  end
end
