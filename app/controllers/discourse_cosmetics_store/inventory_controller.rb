# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class InventoryController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_store_enabled

    def index
      response.headers["Cache-Control"] = "private, no-store"

      unless current_user
        return render json: {
                        inventory: empty_inventory,
                        collections: [],
                        viewer: { logged_in: false },
                      }
      end

      products = collection_products
      items = inventory_items(products)
      owned_item_ids = CosmeticsAccess.owned_item_ids(user: current_user, items: items)
      entitled_item_ids = CosmeticsAccess.entitled_item_ids(user: current_user, items: items)

      render json: {
               inventory:
                 collections_only? ?
                   empty_inventory :
                   inventory_payload(
                     items: visible_items(items, owned_item_ids, entitled_item_ids),
                     catalog_count: items.length,
                     owned_item_ids: owned_item_ids,
                     entitled_item_ids: entitled_item_ids,
                   ),
               collections: collection_progress_payload(
                 products: products,
                 items_by_id: items.index_by(&:id),
                 owned_item_ids: owned_item_ids,
                 entitled_item_ids: entitled_item_ids,
               ),
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

    def collections_only?
      params[:scope].to_s == "collections"
    end

    def collection_products
      Product.available
        .where.not(collection_slug: [nil, ""])
        .ordered
        .includes(:product_items)
        .to_a
    end

    def inventory_items(products)
      scope =
        if collections_only?
          item_ids = products.flat_map { |product| product.product_items.map(&:cosmetic_item_id) }.uniq
          DiscourseUserCosmetics::Item.enabled.where(id: item_ids)
        else
          DiscourseUserCosmetics::Item.enabled.ordered
        end

      scope.includes(:image_upload, effect_layers: :image_upload).to_a
    end

    def visible_items(items, owned_item_ids, entitled_item_ids)
      items.select do |item|
        owned_item_ids.key?(item.id) || entitled_item_ids.key?(item.id)
      end
    end

    def empty_inventory
      {
        items: [],
        stats: {
          catalog_count: 0,
          visible_count: 0,
          directly_owned_count: 0,
          unlocked_count: 0,
        },
        kinds: [],
      }
    end

    def inventory_payload(items:, catalog_count:, owned_item_ids:, entitled_item_ids:)
      rows =
        items.map do |item|
          serialize_item(
            item,
            directly_owned: owned_item_ids.key?(item.id),
            unlocked: entitled_item_ids.key?(item.id),
          )
        end

      {
        items: rows,
        stats: {
          catalog_count: catalog_count,
          visible_count: rows.length,
          directly_owned_count: rows.count { |row| row[:directly_owned] },
          unlocked_count: rows.count { |row| row[:unlocked] },
        },
        kinds:
          rows
            .group_by { |row| row[:kind] }
            .map do |kind, kind_rows|
              {
                kind: kind,
                visible_count: kind_rows.length,
                directly_owned_count: kind_rows.count { |row| row[:directly_owned] },
                unlocked_count: kind_rows.count { |row| row[:unlocked] },
              }
            end
            .sort_by { |row| DiscourseUserCosmetics::Item::KINDS.index(row[:kind]) || 999 },
      }
    end

    def serialize_item(item, directly_owned:, unlocked:)
      DiscourseUserCosmetics::Presenter.serialize_item(item).merge(
        kind: item.kind,
        description: item.description,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
        is_default: item.is_default?,
        directly_owned: directly_owned,
        unlocked: unlocked,
      )
    end

    def collection_progress_payload(products:, items_by_id:, owned_item_ids:, entitled_item_ids:)
      products
        .group_by(&:collection_slug)
        .map do |slug, rows|
          item_ids =
            rows
              .flat_map { |product| product.product_items.map(&:cosmetic_item_id) }
              .uniq
              .select { |item_id| items_by_id.key?(item_id) }
          directly_owned_count = item_ids.count { |item_id| owned_item_ids.key?(item_id) }
          unlocked_count = item_ids.count { |item_id| entitled_item_ids.key?(item_id) }
          total = item_ids.length

          {
            slug: slug,
            name:
              rows.filter_map { |product| product.collection_name.presence }.first ||
                slug.tr("-", " ").titleize,
            image_url:
              rows.filter_map { |product| product.collection_image_url.presence }.first ||
                rows.filter_map { |product| product.hero_image_url.presence }.first,
            product_ids: rows.map(&:id),
            product_count: rows.length,
            item_count: total,
            directly_owned_item_count: directly_owned_count,
            unlocked_item_count: unlocked_count,
            directly_owned_percent: percentage(directly_owned_count, total),
            unlocked_percent: percentage(unlocked_count, total),
            directly_owned_complete: total.positive? && directly_owned_count == total,
            unlocked_complete: total.positive? && unlocked_count == total,
          }
        end
        .sort_by { |collection| collection[:name] }
    end

    def percentage(value, total)
      return 0 if total.zero?

      ((value.to_f / total) * 100).round
    end
  end
end
