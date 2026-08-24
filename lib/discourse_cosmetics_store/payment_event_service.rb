# frozen_string_literal: true

require "digest"

module ::DiscourseCosmeticsStore
  class PaymentEventService
    class PayloadMismatch < StandardError; end

    def self.process!(provider:, external_id:, raw_body:, payment: nil)
      event_key = external_id.to_s[0, 190]
      digest = Digest::SHA256.hexdigest(raw_body.to_s)
      event = find_or_create_event!(provider, event_key, digest, payment)

      unless ActiveSupport::SecurityUtils.secure_compare(event.payload_digest, digest)
        raise PayloadMismatch, "Aynı sağlayıcı olay kimliği farklı bir içerikle tekrar kullanıldı"
      end

      event.with_lock do
        return :duplicate if event.status == "completed"

        event.update!(
          payment_id: payment&.id || event.payment_id,
          status: "processing",
          error_message: nil,
        )
        yield(event)
        event.update!(status: "completed", processed_at: Time.zone.now)
      end
      :processed
    rescue StandardError => error
      if event
        PaymentEvent
          .where(id: event.id)
          .where.not(status: "completed")
          .update_all(
            status: "failed",
            error_message: error.message.to_s[0, 500],
            processed_at: Time.zone.now,
            updated_at: Time.zone.now,
          )
      end
      raise
    end

    def self.find_or_create_event!(provider, external_id, digest, payment)
      PaymentEvent.create!(
        provider: provider,
        external_id: external_id,
        payment_id: payment&.id,
        payload_digest: digest,
        status: "received",
      )
    rescue ActiveRecord::RecordNotUnique
      PaymentEvent.find_by!(provider: provider, external_id: external_id)
    end
    private_class_method :find_or_create_event!
  end
end
