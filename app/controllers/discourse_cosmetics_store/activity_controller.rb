# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class ActivityController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    EVENT_LIMIT = 100
    DUPLICATE_LEDGER_TYPES = %w[purchase gift].freeze

    before_action :ensure_store_enabled

    def index
      no_store!

      unless current_user
        return render json: {
                        activity: empty_activity,
                        viewer: { logged_in: false },
                      }
      end

      render json: {
               activity: {
                 events: activity_events,
                 stats: activity_stats,
                 wallet: wallet_payload,
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

    def no_store!
      response.headers["Cache-Control"] = "private, no-store"
    end

    def activity_events
      (purchase_events + sent_gift_events + received_gift_events + orb_events)
        .sort_by { |event| [event[:created_at], event[:sort_id]] }
        .reverse
        .first(EVENT_LIMIT)
        .map { |event| event.except(:sort_id) }
    end

    def purchase_events
      Purchase
        .where(user_id: current_user.id)
        .includes(:product)
        .order(created_at: :desc, id: :desc)
        .limit(EVENT_LIMIT)
        .map do |purchase|
          {
            id: "purchase:#{purchase.id}",
            sort_id: purchase.id,
            kind: "purchase",
            status: purchase.status,
            amount: -purchase.price_paid,
            created_at: purchase.created_at,
            product: serialize_product(purchase.product),
          }
        end
    end

    def sent_gift_events
      Gift
        .where(sender_id: current_user.id)
        .includes(:product, :recipient)
        .order(created_at: :desc, id: :desc)
        .limit(EVENT_LIMIT)
        .map do |gift|
          {
            id: "gift_sent:#{gift.id}",
            sort_id: gift.id,
            kind: "gift_sent",
            status: gift.status,
            amount: -gift.price_paid,
            created_at: gift.created_at,
            product: serialize_product(gift.product),
            counterparty: { username: gift.recipient.username },
          }
        end
    end

    def received_gift_events
      Gift
        .where(recipient_id: current_user.id)
        .includes(:product, :sender)
        .order(created_at: :desc, id: :desc)
        .limit(EVENT_LIMIT)
        .map do |gift|
          {
            id: "gift_received:#{gift.id}",
            sort_id: gift.id,
            kind: "gift_received",
            status: gift.status,
            created_at: gift.created_at,
            product: serialize_product(gift.product),
            counterparty: { username: gift.sender.username },
          }
        end
    end

    def orb_events
      LedgerEntry
        .where(user_id: current_user.id)
        .where.not(entry_type: DUPLICATE_LEDGER_TYPES)
        .order(created_at: :desc, id: :desc)
        .limit(EVENT_LIMIT)
        .map do |entry|
          {
            id: "orb:#{entry.id}",
            sort_id: entry.id,
            kind: "orb",
            entry_type: entry.entry_type,
            amount: entry.amount,
            debt_delta: entry.debt_delta,
            balance_after: entry.balance_after,
            debt_after: entry.debt_after,
            created_at: entry.created_at,
          }
        end
    end

    def activity_stats
      {
        purchases: Purchase.where(user_id: current_user.id).count,
        gifts_sent: Gift.where(sender_id: current_user.id).count,
        gifts_received: Gift.where(recipient_id: current_user.id).count,
        orb_events:
          LedgerEntry
            .where(user_id: current_user.id)
            .where.not(entry_type: DUPLICATE_LEDGER_TYPES)
            .count,
      }
    end

    def wallet_payload
      wallet = Wallet.find_by(user_id: current_user.id)

      {
        balance: wallet&.balance.to_i,
        debt: wallet&.debt.to_i,
        lifetime_earned: wallet&.lifetime_earned.to_i,
        lifetime_spent: wallet&.lifetime_spent.to_i,
      }
    end

    def serialize_product(product)
      {
        id: product.id,
        name: product.name,
        slug: product.slug,
        product_type: product.product_type,
        card_image_url: product.card_image_url,
        rarity_label: product.rarity_label,
        rarity_color: product.rarity_color,
        collection_name: product.collection_name,
        collection_slug: product.collection_slug,
      }
    end

    def empty_activity
      {
        events: [],
        stats: {
          purchases: 0,
          gifts_sent: 0,
          gifts_received: 0,
          orb_events: 0,
        },
        wallet: {
          balance: 0,
          debt: 0,
          lifetime_earned: 0,
          lifetime_spent: 0,
        },
      }
    end
  end
end
