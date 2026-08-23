# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class AdminController < ::Admin::AdminController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_current_user_is_admin

    def index
      products =
        Product
          .ordered
          .includes(product_items: { cosmetic_item: [:image_upload, { effect_layers: :image_upload }] })
      cosmetic_items =
        DiscourseUserCosmetics::Item
          .ordered
          .includes(:image_upload, effect_layers: :image_upload)

      render json: {
               products: products.map { |product| serialize_product(product) },
               cosmetic_items: cosmetic_items.map { |item| serialize_cosmetic_item(item) },
               missions: Mission.ordered.map { |mission| serialize_mission(mission) },
               mission_metrics:
                 Mission::METRICS.map { |metric| { value: metric, label: metric_label(metric) } },
               settings: {
                 currency_name: SiteSetting.discourse_cosmetics_store_currency_name,
                 currency_symbol: SiteSetting.discourse_cosmetics_store_currency_symbol,
               },
             }
    end

    def create_product
      product = Product.new(product_params)
      product.created_by_id = current_user.id
      save_product(product)
    end

    def update_product
      product = Product.find(params[:id])
      product.assign_attributes(product_params)
      save_product(product)
    end

    def destroy_product
      product = Product.find(params[:id])
      if product.purchases.exists?
        return render_error(
          I18n.t("discourse_cosmetics_store.errors.product_has_purchases"),
          :unprocessable_entity,
        )
      end

      product.destroy!
      Catalog.bump!
      render json: success_json
    end

    def create_mission
      mission = Mission.new(mission_params)
      save_mission(mission)
    end

    def update_mission
      mission = Mission.find(params[:id])
      mission.assign_attributes(mission_params)
      save_mission(mission)
    end

    def destroy_mission
      mission = Mission.find(params[:id])
      if mission.claims.exists?
        mission.update!(enabled: false)
      else
        mission.destroy!
      end
      render json: success_json
    end

    def wallet
      user = find_user!(params[:username])
      wallet = WalletService.fetch(user)
      render json: serialize_wallet(user, wallet)
    end

    def adjust_wallet
      user = find_user!(params[:username])
      amount = params[:amount].to_i
      reason = params[:reason].to_s.strip[0, 500]
      if amount.zero? || amount.abs > 1_000_000 || reason.blank?
        return render_error(I18n.t("discourse_cosmetics_store.errors.invalid_amount"), :unprocessable_entity)
      end

      wallet = WalletService.adjust!(
        user: user,
        amount: amount,
        reason: reason,
        created_by: current_user,
      )
      render json: serialize_wallet(user, wallet).merge(
        message: I18n.t("discourse_cosmetics_store.messages.wallet_adjusted"),
      )
    rescue WalletService::InsufficientBalance, WalletService::BalanceLimitExceeded
      render_error(I18n.t("discourse_cosmetics_store.errors.invalid_amount"), :unprocessable_entity)
    end

    private

    def ensure_current_user_is_admin
      raise Discourse::InvalidAccess unless current_user&.admin?
    end

    def save_product(product)
      cosmetic_item_ids =
        Array(params.dig(:product, :cosmetic_item_ids)).map(&:to_i).reject(&:zero?).uniq
      expected_count = product.product_type == "bundle" ? 2 : 1
      valid_count =
        product.product_type == "bundle" ? cosmetic_item_ids.length >= expected_count : cosmetic_item_ids.length == expected_count

      unless valid_count
        return render_error(
          product.product_type == "bundle" ?
            "Bir paket en az iki kozmetik içermelidir." :
            "Tekli ürün tam olarak bir kozmetik içermelidir.",
          :unprocessable_entity,
        )
      end

      valid_ids = DiscourseUserCosmetics::Item.enabled.where(id: cosmetic_item_ids).pluck(:id)
      unless valid_ids.length == cosmetic_item_ids.length
        return render_error(
          "Seçilen kozmetiklerden biri bulunamadı veya etkin değil.",
          :unprocessable_entity,
        )
      end

      Product.transaction do
        product.save!
        product.product_items.where.not(cosmetic_item_id: cosmetic_item_ids).destroy_all
        cosmetic_item_ids.each_with_index do |item_id, position|
          row = product.product_items.find_or_initialize_by(cosmetic_item_id: item_id)
          row.position = position
          row.save!
        end
      end

      Catalog.bump!
      render json: serialize_product(product.reload)
    rescue ActiveRecord::RecordInvalid
      render_record_errors(product)
    end

    def save_mission(mission)
      if mission.save
        render json: serialize_mission(mission)
      else
        render_record_errors(mission)
      end
    end

    def product_params
      raw = params.require(:product).permit(
        :name,
        :slug,
        :description,
        :product_type,
        :price,
        :card_image_url,
        :hero_image_url,
        :preview_background_url,
        :rarity_label,
        :rarity_color,
        :sort_order,
        :enabled,
        :featured,
        :editor_pick,
        :exclusive,
        :available_from,
        :available_until,
        :tags,
      )
      raw[:tags] = params.dig(:product, :tags)
      raw
    end

    def mission_params
      params.require(:mission).permit(
        :key,
        :name,
        :description,
        :metric,
        :target,
        :reward,
        :icon,
        :sort_order,
        :enabled,
        :available_from,
        :available_until,
      )
    end

    def serialize_product(product)
      {
        id: product.id,
        name: product.name,
        slug: product.slug,
        description: product.description,
        product_type: product.product_type,
        price: product.price,
        card_image_url: product.card_image_url,
        hero_image_url: product.hero_image_url,
        preview_background_url: product.preview_background_url,
        rarity_label: product.rarity_label,
        rarity_color: product.rarity_color,
        tags: Array(product.tags),
        tags_csv: Array(product.tags).join(", "),
        sort_order: product.sort_order,
        purchase_count: product.purchase_count,
        enabled: product.enabled,
        featured: product.featured,
        editor_pick: product.editor_pick,
        exclusive: product.exclusive,
        available_from: product.available_from&.strftime("%Y-%m-%dT%H:%M"),
        available_until: product.available_until&.strftime("%Y-%m-%dT%H:%M"),
        cosmetic_item_ids: product.product_items.map(&:cosmetic_item_id),
        item_names: product.cosmetic_items.map(&:name),
      }
    end

    def serialize_cosmetic_item(item)
      image_url = item.resolved_image_url
      image_url = DiscourseUserCosmetics::Presenter.effect_fields(item)[:image_url] if item.kind == "profile_effect"
      {
        id: item.id,
        kind: item.kind,
        name: item.name,
        image_url: image_url,
        rarity_label: item.rarity_label,
        enabled: item.enabled,
      }
    end

    def serialize_mission(mission)
      {
        id: mission.id,
        key: mission.key,
        name: mission.name,
        description: mission.description,
        metric: mission.metric,
        target: mission.target,
        reward: mission.reward,
        icon: mission.icon,
        sort_order: mission.sort_order,
        enabled: mission.enabled,
        available_from: mission.available_from&.strftime("%Y-%m-%dT%H:%M"),
        available_until: mission.available_until&.strftime("%Y-%m-%dT%H:%M"),
        claim_count: mission.claims.count,
      }
    end

    def serialize_wallet(user, wallet)
      {
        user: {
          id: user.id,
          username: user.username,
          name: user.name.presence || user.username,
          avatar_url: user.avatar_template.to_s.gsub("{size}", "96"),
        },
        wallet: {
          balance: wallet.balance,
          lifetime_earned: wallet.lifetime_earned,
          lifetime_spent: wallet.lifetime_spent,
          ledger:
            wallet
              .ledger_entries
              .order(created_at: :desc)
              .limit(30)
              .map do |entry|
                {
                  id: entry.id,
                  amount: entry.amount,
                  credit: entry.amount.positive?,
                  balance_after: entry.balance_after,
                  entry_type: entry.entry_type,
                  reason: entry.reason,
                  created_at: entry.created_at&.iso8601,
                }
              end,
        },
      }
    end

    def metric_label(metric)
      {
        "posts_created" => "Oluşturulan gönderi",
        "topics_created" => "Oluşturulan konu",
        "likes_received" => "Alınan beğeni",
        "days_visited" => "Ziyaret edilen gün",
        "trust_level" => "Güven seviyesi",
        "badges_earned" => "Kazanılan rozet",
        "account_age_days" => "Hesap yaşı (gün)",
      }.fetch(metric, metric)
    end

    def find_user!(username)
      user = User.find_by(username_lower: username.to_s.strip.downcase)
      raise Discourse::NotFound unless user
      user
    end

    def render_record_errors(record)
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end

    def render_error(message, status)
      render json: { errors: [message] }, status: status
    end
  end
end
