# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class GiftNotification
    def self.deliver(gift:, sender:, recipient:, product:)
      return unless gift&.persisted? && sender&.persisted? && recipient&.persisted? && product&.persisted?
      return unless Notification.types[DiscourseCosmeticsStore::GIFT_NOTIFICATION_NAME] ==
                      DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE

      data =
        {
          gift_id: gift.id,
          display_username: sender.username,
          product_name: product.name,
        }.to_json

      notification =
        Notification.find_or_initialize_by(
          user_id: recipient.id,
          notification_type: DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE,
          data: data,
        )

      return notification if notification.persisted?

      # Store gifts should surface in the native in-app notification menu without
      # unexpectedly adding an email channel to an existing purchase flow.
      notification.skip_send_email = true
      notification.save!
      notification
    rescue StandardError => error
      # The gift transaction has already committed before this method runs.
      # Notification delivery is deliberately best-effort so a UI-side failure
      # can never make the caller believe a completed financial action failed.
      Rails.logger.warn(
        "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] gift notification failed " \
          "gift_id=#{gift&.id}: #{error.class}: #{error.message}",
      )
      nil
    end
  end
end
