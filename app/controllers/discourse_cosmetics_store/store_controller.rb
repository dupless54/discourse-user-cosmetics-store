# frozen_string_literal: true

module ::DiscourseCosmeticsStore
  class StoreController < ::ApplicationController
    requires_plugin DiscourseCosmeticsStore::PLUGIN_NAME

    before_action :ensure_store_enabled
    before_action :ensure_logged_in,
                  only: %i[purchase favorite unfavorite claim_mission]

    def index
      response.headers["Cache-Control"] = "private, no-store"
      limit = SiteSetting.discourse_cosmetics_store_products_limit.to_i.clamp(12, 300)
      products =
        Product
          .available
          .ordered
          .includes(product_items: { cosmetic_item: [:groups, :image_upload, { effect_layers: :image_upload }] })
          .limit(limit)
          .to_a

      usage_counts = Catalog.usage_counts
      purchased_ids = viewer_purchase_ids
      favorite_ids = viewer_favorite_ids
      access_context = viewer_access_context
      serialized =
        products.map do |product|
          serialize_product(
            product,
            usage_counts: usage_counts,
            purchased_ids: purchased_ids,
            favorite_ids: favorite_ids,
            access_context: access_context,
          )
        end

      wallet = current_user ? WalletService.fetch(current_user) : nil
      missions = serialize_missions

      render json: {
               products: serialized,
               sections: {
                 editor_picks:
                   serialized.select { |product| product[:editor_pick] }.map { |product| product[:id] },
                 featured:
                   serialized.select { |product| product[:featured] }.map { |product| product[:id] },
                 popular:
                   serialized
                     .sort_by { |product| [-product[:popularity_score], product[:sort_order], product[:id]] }
                     .first(12)
                     .map { |product| product[:id] },
                 bundles:
                   serialized.select { |product| product[:product_type] == "bundle" }.first(12).map { |product| product[:id] },
                 profile_effects:
                   serialized.select { |product| product[:kinds].include?("profile_effect") }.first(12).map { |product| product[:id] },
                 newest:
                   serialized.sort_by { |product| product[:created_at].to_s }.reverse.first(12).map { |product| product[:id] },
               },
               filters: filter_payload(serialized),
               missions: missions,
               orb_packages: serialize_orb_packages,
               payment_providers: PaymentProviders.enabled,
               payments: serialize_recent_payments,
               wallet: serialize_wallet(wallet),
               viewer: {
                 logged_in: current_user.present?,
                 is_admin: current_user&.admin? || false,
                 can_purchase: current_user.present?,
                 favorites_enabled: SiteSetting.discourse_cosmetics_store_favorites_enabled,
                 missions_enabled: SiteSetting.discourse_cosmetics_store_missions_enabled,
                 payments_enabled: SiteSetting.discourse_cosmetics_store_payments_enabled,
                 preview_user: serialize_preview_user,
               },
               settings: {
                 currency_name: SiteSetting.discourse_cosmetics_store_currency_name,
                 currency_symbol: SiteSetting.discourse_cosmetics_store_currency_symbol,
                 hero_title: SiteSetting.discourse_cosmetics_store_hero_title,
                 hero_subtitle: SiteSetting.discourse_cosmetics_store_hero_subtitle,
                 editor_title: SiteSetting.discourse_cosmetics_store_editor_title,
                 hover_preview: SiteSetting.discourse_cosmetics_store_hover_preview_enabled,
               },
             }
    end

    def purchase
      product = Product.find(params[:id])
      service = PurchaseService.new(user: current_user, product: product).call

      render json: {
               product_id: service.product.id,
               balance: service.wallet.balance,
               granted_item_ids: service.product.cosmetic_items.map(&:id),
               message: I18n.t("discourse_cosmetics_store.messages.purchased"),
             }
    rescue PurchaseService::Unavailable, PurchaseService::EmptyProduct
      render_error(I18n.t("discourse_cosmetics_store.errors.unavailable"), :unprocessable_entity)
    rescue PurchaseService::AlreadyOwned
      render_error(I18n.t("discourse_cosmetics_store.errors.already_owned"), :unprocessable_entity)
    rescue WalletService::InsufficientBalance
      render_error(I18n.t("discourse_cosmetics_store.errors.insufficient_balance"), :unprocessable_entity)
    end

    def favorite
      ensure_favorites_enabled
      product = Product.available.find(params[:id])
      Favorite.find_or_create_by!(user_id: current_user.id, product_id: product.id)
      render json: {
               product_id: product.id,
               favorite: true,
               message: I18n.t("discourse_cosmetics_store.messages.favorite_added"),
             }
    end

    def unfavorite
      ensure_favorites_enabled
      Favorite.where(user_id: current_user.id, product_id: params[:id]).destroy_all
      render json: {
               product_id: params[:id].to_i,
               favorite: false,
               message: I18n.t("discourse_cosmetics_store.messages.favorite_removed"),
             }
    end

    def claim_mission
      mission = Mission.find(params[:id])
      service = MissionClaimService.new(user: current_user, mission: mission).call

      render json: {
               mission_id: service.mission.id,
               balance: service.wallet.balance,
               claimed: true,
               message: I18n.t("discourse_cosmetics_store.messages.mission_claimed"),
             }
    rescue MissionClaimService::Unavailable
      render_error(I18n.t("discourse_cosmetics_store.errors.mission_unavailable"), :unprocessable_entity)
    rescue MissionClaimService::Incomplete
      render_error(I18n.t("discourse_cosmetics_store.errors.mission_incomplete"), :unprocessable_entity)
    rescue MissionClaimService::AlreadyClaimed
      render_error(I18n.t("discourse_cosmetics_store.errors.mission_claimed"), :unprocessable_entity)
    rescue WalletService::BalanceLimitExceeded
      render_error("Cüzdanın en yüksek bakiye sınırına ulaştı.", :unprocessable_entity)
    end

    private

    def ensure_store_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_enabled
    end

    def ensure_favorites_enabled
      raise Discourse::NotFound unless SiteSetting.discourse_cosmetics_store_favorites_enabled
    end

    def viewer_purchase_ids
      return Set.new unless current_user

      Purchase.where(user_id: current_user.id, status: "completed").pluck(:product_id).to_set
    end

    def viewer_favorite_ids
      return Set.new unless current_user && SiteSetting.discourse_cosmetics_store_favorites_enabled

      Favorite.where(user_id: current_user.id).pluck(:product_id).to_set
    end

    def serialize_product(product, usage_counts:, purchased_ids:, favorite_ids:, access_context:)
      items = product.cosmetic_items
      item_rows = items.map { |item| serialize_cosmetic_item(item) }
      usage_count = items.sum { |item| usage_counts[item.id].to_i }
      purchased = purchased_ids.include?(product.id)
      unlocked = items.present? && items.all? { |item| item_unlocked_for_viewer?(item, access_context) }

      {
        id: product.id,
        slug: product.slug,
        name: product.name,
        description: product.description,
        product_type: product.product_type,
        item_count: item_rows.length,
        price: product.price,
        card_image_url: product.card_image_url.presence || item_rows.find { |row| row[:image_url].present? }&.dig(:image_url),
        hero_image_url: product.hero_image_url,
        preview_background_url: product.preview_background_url,
        rarity_label: product.rarity_label.presence || item_rows.first&.dig(:rarity_label),
        rarity_color: product.rarity_color.presence || item_rows.first&.dig(:rarity_color),
        tags: Array(product.tags),
        kinds: item_rows.map { |item| item[:kind] }.uniq,
        items: item_rows,
        featured: product.featured,
        editor_pick: product.editor_pick,
        exclusive: product.exclusive,
        sort_order: product.sort_order,
        purchase_count: product.purchase_count,
        usage_count: usage_count,
        popularity_score: product.purchase_count.to_i * 10 + usage_count,
        purchased: purchased,
        owned: purchased || unlocked,
        favorite: favorite_ids.include?(product.id),
        purchasable: current_user.present? && !purchased && !unlocked && product.available_now?,
        available_from: product.available_from&.iso8601,
        available_until: product.available_until&.iso8601,
        created_at: product.created_at&.iso8601,
      }
    end

    def serialize_cosmetic_item(item)
      payload = {
        id: item.id,
        kind: item.kind,
        kind_label: kind_label(item.kind),
        name: item.name,
        description: item.description,
        image_url: item.resolved_image_url,
        gradient_from: item.gradient_from,
        gradient_to: item.gradient_to,
        glow_color: item.glow_color,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
      }

      if item.kind == "profile_effect"
        effect_fields = DiscourseUserCosmetics::Presenter.effect_fields(item)
        effect_fields[:image_url] = payload[:image_url] if effect_fields[:image_url].blank?
        payload.merge!(effect_fields)
      end

      payload
    end

    def viewer_access_context
      return nil unless current_user

      {
        user_item_ids:
          DiscourseUserCosmetics::UserItem
            .where(user_id: current_user.id)
            .pluck(:item_id)
            .to_set,
        group_ids: current_user.group_ids.to_set,
        locked_item_ids: Catalog.locked_item_ids.to_set,
      }
    end

    def item_unlocked_for_viewer?(item, context)
      return false unless context
      return true if item.is_default?

      group_access = item.groups.any? { |group| context[:group_ids].include?(group.id) }
      directly_owned = context[:user_item_ids].include?(item.id)

      if SiteSetting.discourse_cosmetics_store_enabled && context[:locked_item_ids].include?(item.id)
        group_access || directly_owned
      else
        item.groups.empty? || group_access || directly_owned
      end
    end

    def kind_label(kind)
      {
        "avatar_frame" => "Avatar çerçevesi",
        "nameplate" => "İsim plakası",
        "card_decoration" => "Kart dekorasyonu",
        "profile_effect" => "Profil efekti",
      }.fetch(kind, kind)
    end

    def serialize_missions
      return [] unless SiteSetting.discourse_cosmetics_store_missions_enabled

      missions = Mission.available.ordered.to_a
      claimed_ids =
        current_user ? MissionClaim.where(user_id: current_user.id, mission_id: missions.map(&:id)).pluck(:mission_id).to_set : Set.new

      missions.map do |mission|
        progress = MissionProgress.for(current_user, mission)
        {
          id: mission.id,
          key: mission.key,
          name: mission.name,
          description: mission.description,
          metric: mission.metric,
          target: mission.target,
          reward: mission.reward,
          icon: mission.icon.presence || "✦",
          progress: progress,
          progress_percent: [(progress.to_f / mission.target * 100).round, 100].min,
          complete: progress >= mission.target,
          claimed: claimed_ids.include?(mission.id),
        }
      end
    end

    def serialize_wallet(wallet)
      return { balance: 0, lifetime_earned: 0, lifetime_spent: 0, ledger: [] } unless wallet

      {
        balance: wallet.balance,
        lifetime_earned: wallet.lifetime_earned,
        lifetime_spent: wallet.lifetime_spent,
        ledger:
          wallet
            .ledger_entries
            .order(created_at: :desc)
            .limit(12)
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
      }
    end

    def serialize_orb_packages
      providers = PaymentProviders.enabled.map { |row| row[:id] }
      return [] if providers.empty?

      OrbPackage.available.filter_map do |package|
        available = providers.select { |provider| package.provider_enabled?(provider) }
        next if available.empty?

        {
          id: package.id,
          name: package.name,
          description: package.description,
          orb_amount: package.orb_amount,
          price_minor: package.price_minor,
          price: format("%.2f", BigDecimal(package.price_minor.to_s) / 100),
          currency: package.currency,
          featured: package.featured,
          providers: available,
        }
      end
    end

    def serialize_recent_payments
      return [] unless current_user && SiteSetting.discourse_cosmetics_store_payments_enabled

      Payment.where(user_id: current_user.id).recent.limit(10).map do |payment|
        {
          token: payment.token,
          provider: payment.provider,
          status: payment.status,
          orb_amount: payment.orb_amount,
          amount_minor: payment.amount_minor,
          currency: payment.currency,
          completed_at: payment.completed_at&.iso8601,
          created_at: payment.created_at&.iso8601,
        }
      end
    end

    def serialize_preview_user
      return {
               name: "Topluluk üyesi",
               username: "kullanici",
               avatar_url: nil,
               card_background_url: nil,
               profile_background_url: nil,
             } unless current_user

      profile = current_user.user_profile

      {
        name: current_user.name.presence || current_user.username,
        username: current_user.username,
        avatar_url: current_user.avatar_template.to_s.gsub("{size}", "240"),
        card_background_url: profile&.card_background_upload&.url,
        profile_background_url: profile&.profile_background_upload&.url,
      }
    end

    def filter_payload(products)
      {
        kinds:
          products
            .flat_map { |product| product[:items] }
            .group_by { |item| item[:kind] }
            .map do |kind, items|
              { value: kind, label: kind_label(kind), count: items.map { |item| item[:id] }.uniq.length }
            end,
        rarities:
          products
            .filter_map { |product| product[:rarity_label].presence }
            .tally
            .map { |label, count| { value: label, label: label, count: count } },
        tags:
          products
            .flat_map { |product| product[:tags] }
            .tally
            .sort_by { |tag, count| [-count, tag] }
            .map { |tag, count| { value: tag, label: tag.tr("-", " "), count: count } },
      }
    end

    def render_error(message, status)
      render json: { errors: [message] }, status: status
    end
  end
end
