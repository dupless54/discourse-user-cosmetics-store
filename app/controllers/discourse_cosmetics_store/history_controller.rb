# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class HistoryController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    HISTORY_LIMIT = 100

    before_action :ensure_store_enabled

    def index
      response.headers["Cache-Control"] = "private, no-store"

      unless current_user
        return render json: {
                        history: empty_history,
                        viewer: { logged_in: false },
                      }
      end

      purchases = purchase_scope
      gifts_sent = sent_gift_scope
      gifts_received = received_gift_scope

      render json: {
               history: {
                 purchases: purchases.limit(HISTORY_LIMIT).map { |purchase| serialize_purchase(purchase) },
                 gifts_sent: gifts_sent.limit(HISTORY_LIMIT).map { |gift| serialize_gift(gift, direction: :sent) },
                 gifts_received:
                   gifts_received.limit(HISTORY_LIMIT).map do |gift|
                     serialize_gift(gift, direction: :received)
                   end,
                 stats: {
                   purchase_count: purchases.count,
                   gifts_sent_count: gifts_sent.count,
                   gifts_received_count: gifts_received.count,
                 },
                 limits: {
                   purchases: HISTORY_LIMIT,
                   gifts_sent: HISTORY_LIMIT,
                   gifts_received: HISTORY_LIMIT,
                 },
               },
               viewer: {
                 logged_in: true,
                 username: current_user.username,
               },
             }
    end

    private

    def ensure_store_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_enabled
    end

    def purchase_scope
      Purchase
        .where(user_id: current_user.id)
        .includes(:product)
        .order(created_at: :desc, id: :desc)
    end

    def sent_gift_scope
      Gift
        .where(sender_id: current_user.id)
        .includes(:product, :recipient)
        .order(created_at: :desc, id: :desc)
    end

    def received_gift_scope
      Gift
        .where(recipient_id: current_user.id)
        .includes(:product, :sender)
        .order(created_at: :desc, id: :desc)
    end

    def empty_history
      {
        purchases: [],
        gifts_sent: [],
        gifts_received: [],
        stats: {
          purchase_count: 0,
          gifts_sent_count: 0,
          gifts_received_count: 0,
        },
        limits: {
          purchases: HISTORY_LIMIT,
          gifts_sent: HISTORY_LIMIT,
          gifts_received: HISTORY_LIMIT,
        },
      }
    end

    def serialize_purchase(purchase)
      {
        id: purchase.id,
        price_paid: purchase.price_paid,
        status: purchase.status,
        created_at: purchase.created_at,
        product: serialize_product(purchase.product),
      }
    end

    def serialize_gift(gift, direction:)
      other_user = direction == :sent ? gift.recipient : gift.sender

      {
        id: gift.id,
        direction: direction,
        price_paid: gift.price_paid,
        status: gift.status,
        created_at: gift.created_at,
        product: serialize_product(gift.product),
        user: serialize_user(other_user),
      }
    end

    def serialize_product(product)
      return nil unless product

      {
        id: product.id,
        name: product.name,
        slug: product.slug,
        product_type: product.product_type,
        image_url:
          product.card_image_url.presence ||
            product.hero_image_url.presence ||
            product.preview_background_url.presence,
      }
    end

    def serialize_user(user)
      return nil unless user

      {
        id: user.id,
        username: user.username,
        path: "/u/#{user.username_lower}",
      }
    end
  end
end
