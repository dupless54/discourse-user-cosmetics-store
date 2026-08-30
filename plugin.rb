# frozen_string_literal: true

# name: discourse-user-cosmetics-store
# about: Discord tarzı Orbs mağazası, görevler ve discourse-user-cosmetics entegrasyonu.
# version: 1.3.1
# authors: dupless54
# url: https://senin.me/store
# required_version: 3.3.0

enabled_site_setting :discourse_cosmetics_store_enabled

register_asset "stylesheets/discourse-cosmetics-store.scss"
register_asset "stylesheets/discourse-cosmetics-store-native.scss"
register_asset "stylesheets/discourse-cosmetics-store-polish.scss"
register_asset "stylesheets/discourse-cosmetics-store-loadouts.scss"
register_asset "stylesheets/discourse-cosmetics-store-preview.scss"
register_asset "stylesheets/discourse-cosmetics-store-availability.scss"
register_asset "stylesheets/discourse-cosmetics-store-accessibility.scss"
register_asset "stylesheets/discourse-cosmetics-store-wardrobe.scss"
register_asset "stylesheets/discourse-cosmetics-store-activity.scss"
register_asset "stylesheets/discourse-cosmetics-store-mobile.scss"
register_asset "stylesheets/discourse-cosmetics-store-responsive-native.scss"
register_asset "stylesheets/discourse-cosmetics-store-navigation.scss"
register_asset "stylesheets/discourse-cosmetics-store-dialog-responsive.scss"

%w[cart-shopping check clock eye gift heart image palette paper-plane right-to-bracket xmark].each do |icon|
  register_svg_icon icon
end

module ::DiscourseCosmeticsStore
  PLUGIN_NAME = "discourse-user-cosmetics-store"
  VERSION = "1.3.1"
  BASE_PLUGIN_NAME = "discourse-user-cosmetics"
  GIFT_NOTIFICATION_NAME = :cosmetics_store_gift
  GIFT_NOTIFICATION_TYPE = 12_001
  BASE_PLUGIN_RUBY_FILES = %w[
    app/models/discourse_user_cosmetics/item.rb
    app/models/discourse_user_cosmetics/item_group.rb
    app/models/discourse_user_cosmetics/user_item.rb
    app/models/discourse_user_cosmetics/user_selection.rb
    app/models/discourse_user_cosmetics/effect_layer.rb
    lib/discourse_user_cosmetics/presenter.rb
  ].freeze
  BASE_PLUGIN_INTEGRATION_RUBY_FILES = %w[
    lib/discourse_user_cosmetics/entitlement_resolver.rb
    lib/discourse_user_cosmetics/selection_service.rb
    lib/discourse_user_cosmetics/integration.rb
  ].freeze
  BASE_PLUGIN_LOADOUT_RUBY_FILES = %w[
    app/models/discourse_user_cosmetics/loadout.rb
    lib/discourse_user_cosmetics/loadout_service.rb
  ].freeze

  def self.install_notification_type!
    existing_id = Notification.types[GIFT_NOTIFICATION_NAME]
    existing_name = Notification.types[GIFT_NOTIFICATION_TYPE]

    if (existing_id && existing_id != GIFT_NOTIFICATION_TYPE) ||
         (existing_name && existing_name != GIFT_NOTIFICATION_NAME)
      Rails.logger.error(
        "[#{PLUGIN_NAME}] notification type collision for #{GIFT_NOTIFICATION_NAME}=#{GIFT_NOTIFICATION_TYPE}",
      )
      return false
    end

    Notification.types[GIFT_NOTIFICATION_NAME] = GIFT_NOTIFICATION_TYPE
    true
  end

  def self.base_plugin_ready?
    defined?(::DiscourseUserCosmetics::Item) &&
      defined?(::DiscourseUserCosmetics::ItemGroup) &&
      defined?(::DiscourseUserCosmetics::UserItem) &&
      defined?(::DiscourseUserCosmetics::UserSelection) &&
      defined?(::DiscourseUserCosmetics::Presenter)
  end

  def self.base_integration_ready?
    defined?(::DiscourseUserCosmetics::Integration) &&
      ::DiscourseUserCosmetics::Integration.respond_to?(:register_entitlement_provider) &&
      ::DiscourseUserCosmetics::Integration.respond_to?(:owned_item_ids) &&
      ::DiscourseUserCosmetics::Integration.respond_to?(:owned_items) &&
      ::DiscourseUserCosmetics::Integration.respond_to?(:selected_items)
  end

  def self.base_loadout_ready?
    defined?(::DiscourseUserCosmetics::Loadout) &&
      defined?(::DiscourseUserCosmetics::LoadoutService)
  end

  def self.load_base_plugin_contract!
    return false unless defined?(::DiscourseUserCosmetics)

    base_plugin = Discourse.plugins.find { |plugin| plugin.name == BASE_PLUGIN_NAME }
    return base_plugin_ready? && base_integration_ready? if base_plugin.nil?

    (BASE_PLUGIN_RUBY_FILES + BASE_PLUGIN_INTEGRATION_RUBY_FILES + BASE_PLUGIN_LOADOUT_RUBY_FILES).each do |path|
      full_path = base_plugin.root_dir.join(path)
      require_dependency full_path.to_s if File.exist?(full_path)
    end

    base_plugin_ready? && base_integration_ready?
  end
end

register_notification_consolidation_plan(
  DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE,
  DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE,
)

register_notification_consolidation_plan(
  "cosmetics_store_gift",
  DiscourseCosmeticsStore::GIFT_NOTIFICATION_TYPE,
)

after_initialize do
  DiscourseCosmeticsStore.install_notification_type!
  DiscourseCosmeticsStore.load_base_plugin_contract!

  module ::DiscourseCosmeticsStore
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseCosmeticsStore
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseCosmeticsStore::Engine, at: "/cosmetics-store"
    get "/store" => "discourse_cosmetics_store/store#index"
    get "/store/:tab" => "discourse_cosmetics_store/store#index"
    get "/store/:tab/:filter" => "discourse_cosmetics_store/store#index"
  end

  DiscourseCosmeticsStore::Engine.routes.draw do
    get "/catalog.json" => "catalog#index"
    post "/products/:id/purchase.json" => "purchases#create"
    put "/products/:id/favorite.json" => "favorites#create"
    delete "/products/:id/favorite.json" => "favorites#destroy"
    post "/products/:id/gift.json" => "gifts#create"
    post "/missions/:id/claim.json" => "missions#claim"
    post "/checkout.json" => "checkout#create"
    post "/payments/shopier/callback" => "shopier_callbacks#create"
    get "/inventory.json" => "inventory#index"
    put "/inventory/:id/equip.json" => "inventory#equip"
    delete "/inventory/:kind/unequip.json" => "inventory#unequip"
    get "/loadouts.json" => "loadouts#index"
    post "/loadouts.json" => "loadouts#create"
    put "/loadouts/:id.json" => "loadouts#update"
    delete "/loadouts/:id.json" => "loadouts#destroy"
    post "/loadouts/:id/apply.json" => "loadouts#apply"
    get "/activity.json" => "activity#index"
    get "/collections/progress.json" => "collection_progress#index"
    get "/admin/audit.json" => "admin/audit#index"
    get "/admin/health.json" => "admin/health#index"
  end

  if DiscourseCosmeticsStore.base_integration_ready?
    ::DiscourseUserCosmetics::Integration.register_entitlement_provider(
      DiscourseCosmeticsStore::PLUGIN_NAME,
      ->(user_id) { DiscourseCosmeticsStore::EntitlementResolver.owned_item_ids(user_id) },
    )
  end
end
