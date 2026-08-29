# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class Catalog
    LOCKED_ITEMS_CACHE_KEY = "discourse-cosmetics-store/locked-item-ids"

    def self.locked_item_ids
      Discourse.cache.fetch(LOCKED_ITEMS_CACHE_KEY, expires_in: 10.minutes) do
        ProductItem
          .joins(:product)
          .where(discourse_cosmetics_store_products: { exclusive: true })
          .distinct
          .pluck(:cosmetic_item_id)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def self.item_locked?(item_id)
      locked_item_ids.include?(item_id.to_i)
    end

    def self.usage_counts
      counts = Hash.new(0)
      DiscourseUserCosmetics::UserSelection::FIELD_FOR_KIND.values.each do |field|
        DiscourseUserCosmetics::UserSelection
          .where.not(field => nil)
          .group(field)
          .count
          .each { |item_id, count| counts[item_id.to_i] += count.to_i }
      end
      counts
    end

    def self.bump!
      Discourse.cache.delete(LOCKED_ITEMS_CACHE_KEY)
      return unless defined?(::DiscourseUserCosmetics::Presenter)

      ::DiscourseUserCosmetics::Presenter.bump_version!
    end
  end
end
