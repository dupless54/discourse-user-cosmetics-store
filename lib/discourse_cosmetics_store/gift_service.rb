# frozen_string_literal: true

require_relative "cosmetics_access"

module ::DiscourseCosmeticsStore
  class GiftService
    class Unavailable < StandardError; end
    class InvalidRecipient < StandardError; end
    class AlreadyOwned < StandardError; end
    class EmptyProduct < StandardError; end

    attr_reader :sender, :recipient, :product, :wallet, :gift

    def initialize(sender:, product:, recipient_username:)
      @sender = sender
      @product = product
      @recipient_username = recipient_username.to_s.delete_prefix("@").strip.downcase
    end

    def call
      raise InvalidRecipient if @recipient_username.blank?
      raise InvalidRecipient if @recipient_username.length > SiteSetting.max_username_length

      @recipient = User.find_by(username_lower: @recipient_username)
      raise InvalidRecipient unless valid_recipient?

      Product.transaction do
        @product = Product.lock.includes(cosmetic_items: :groups).find(product.id)
        raise Unavailable unless @product.available_now?
        raise EmptyProduct if @product.cosmetic_items.empty?

        @recipient.lock!
        raise AlreadyOwned if recipient_owns_any_item?
        raise AlreadyOwned if Purchase.where(user_id: recipient.id, product_id: @product.id, status: "completed").exists?
        raise AlreadyOwned if Gift.where(recipient_id: recipient.id, product_id: @product.id, status: "completed").exists?

        idempotency_key = "gift:#{sender.id}:#{recipient.id}:#{@product.id}"
        @wallet =
          WalletService.debit!(
            user: sender,
            amount: @product.price,
            entry_type: "gift",
            idempotency_key: idempotency_key,
            reason: "#{@product.name} → @#{recipient.username}",
            reference_type: "DiscourseCosmeticsStore::Product",
            reference_id: @product.id,
          )

        @gift =
          Gift.create!(
            sender_id: sender.id,
            recipient_id: recipient.id,
            product_id: @product.id,
            price_paid: @product.price,
            status: "completed",
            idempotency_key: idempotency_key,
          )

        @product.cosmetic_items.each do |item|
          CosmeticsAccess.grant!(user: recipient, item: item)
        end

        @product.update_columns(purchase_count: @product.purchase_count.to_i + 1)
      end

      Catalog.bump!
      GiftNotification.deliver(gift: gift, sender: sender, recipient: recipient, product: product)
      self
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyOwned
    end

    private

    def valid_recipient?
      recipient.present? && recipient.id != sender.id && recipient.active? && !recipient.staged?
    end

    def recipient_owns_any_item?
      CosmeticsAccess.entitled_item_ids(user: recipient, items: @product.cosmetic_items).any?
    end
  end
end
