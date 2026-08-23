# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class PurchaseService
    class Unavailable < StandardError; end
    class AlreadyOwned < StandardError; end
    class EmptyProduct < StandardError; end

    attr_reader :user, :product, :wallet, :purchase

    def initialize(user:, product:)
      @user = user
      @product = product
    end

    def call
      idempotency_key = "purchase:#{user.id}:#{product.id}"

      Product.transaction do
        @product = Product.lock.includes(:cosmetic_items).find(product.id)
        raise Unavailable unless @product.available_now?
        raise AlreadyOwned if Purchase.where(user_id: user.id, product_id: @product.id).exists?
        raise EmptyProduct if @product.cosmetic_items.empty?

        @wallet = WalletService.debit!(
          user: user,
          amount: @product.price,
          entry_type: "purchase",
          idempotency_key: idempotency_key,
          reason: @product.name,
          reference_type: "DiscourseCosmeticsStore::Product",
          reference_id: @product.id,
        )

        @purchase = Purchase.create!(
          user_id: user.id,
          product_id: @product.id,
          price_paid: @product.price,
          status: "completed",
          idempotency_key: idempotency_key,
        )

        @product.cosmetic_items.each do |item|
          DiscourseUserCosmetics::UserItem.find_or_create_by!(
            user_id: user.id,
            item_id: item.id,
          )
        end

        @product.update_columns(purchase_count: @product.purchase_count.to_i + 1)
      end

      Catalog.bump!
      self
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyOwned
    end
  end
end
