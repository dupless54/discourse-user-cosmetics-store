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

%w[cart-shopping check eye gift heart image palette paper-plane right-to-bracket xmark].each do |icon|
  register_svg_icon icon
end

module ::DiscourseCosmeticsStore
  PLUGIN_NAME = "discourse-user-cosmetics-store"
  VERSION = "1.3.1"
  BASE_PLUGIN_NAME = "discourse-user-cosmetics"
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
      ::DiscourseUserCosmetics::Integration.respond_to?(:entitled_item_ids) &&
      ::DiscourseUserCosmetics::Integration.respond_to?(:grant!)
  end

  def self.base_plugin_root
    if defined?(::DiscourseUserCosmetics) &&
         ::DiscourseUserCosmetics.respond_to?(:const_source_location)
      source = ::DiscourseUserCosmetics.const_source_location(:PLUGIN_NAME)&.first
      return File.dirname(source) if source.present?
    end

    File.expand_path("../#{BASE_PLUGIN_NAME}", __dir__)
  end

  # Plugin initializers are not a dependency graph. During `db:migrate`, a
  # companion plugin can be initialized before the base plugin's own
  # `after_initialize` callback has required its models. Load only the public
  # model/presenter files we integrate with so rebuilds do not depend on plugin
  # callback order. The newer Integration contract is optional here so a Store
  # update remains compatible with an older base plugin during rolling deploys.
  def self.load_base_plugin!
    return false unless defined?(::DiscourseUserCosmetics)

    root = base_plugin_root
    return false unless File.directory?(root)

    unless base_plugin_ready?
      BASE_PLUGIN_RUBY_FILES.each do |relative_path|
        absolute_path = File.join(root, relative_path)
        return false unless File.file?(absolute_path)

        require absolute_path
      end
    end

    load_base_integration_if_available!(root)
    load_base_loadouts_if_available!(root)
    base_plugin_ready?
  rescue StandardError, LoadError => error
    Rails.logger.error(
      "[#{PLUGIN_NAME}] could not load #{BASE_PLUGIN_NAME}: " \
        "#{error.class}: #{error.message}",
    )
    false
  end

  def self.load_base_integration_if_available!(root = base_plugin_root)
    return true if base_integration_ready?

    BASE_PLUGIN_INTEGRATION_RUBY_FILES.each do |relative_path|
      absolute_path = File.join(root, relative_path)
      return false unless File.file?(absolute_path)

      require absolute_path
    end

    base_integration_ready?
  end

  def self.load_base_loadouts_if_available!(root = base_plugin_root)
    return true if defined?(::DiscourseUserCosmetics::Loadout) &&
      defined?(::DiscourseUserCosmetics::LoadoutService)

    return false unless BASE_PLUGIN_LOADOUT_RUBY_FILES.all? { |path| File.file?(File.join(root, path)) }

    BASE_PLUGIN_LOADOUT_RUBY_FILES.each { |path| require File.join(root, path) }
    defined?(::DiscourseUserCosmetics::Loadout) && defined?(::DiscourseUserCosmetics::LoadoutService)
  end

  def self.install_item_access_extension!
    return false unless load_base_plugin!
    return true if ::DiscourseUserCosmetics::Item < ItemAccessExtension

    ::DiscourseUserCosmetics::Item.prepend(ItemAccessExtension)
    true
  end

  def self.install_cosmetics_integration!
    return false unless load_base_plugin!

    if base_integration_ready?
      ::DiscourseUserCosmetics::Integration.register_entitlement_provider(PLUGIN_NAME) do |**kwargs|
        EntitlementProvider.call(**kwargs)
      end
      true
    else
      install_item_access_extension!
    end
  end
end

after_initialize do
  Rails.application.config.filter_parameters += %i[
    identity_number
    address
    phone
    shopier_osb_password
    shopier_osb_username
    shopier_webhook_token
    stripe_secret_key
    stripe_webhook_secret
    paypal_client_secret
    paytr_merchant_key
    paytr_merchant_salt
    iyzico_secret_key
    shipy_api_key
  ]

  require_relative "app/models/discourse_cosmetics_store/product"
  require_relative "app/models/discourse_cosmetics_store/product_item"
  require_relative "app/models/discourse_cosmetics_store/wallet"
  require_relative "app/models/discourse_cosmetics_store/ledger_entry"
  require_relative "app/models/discourse_cosmetics_store/purchase"
  require_relative "app/models/discourse_cosmetics_store/gift"
  require_relative "app/models/discourse_cosmetics_store/mission"
  require_relative "app/models/discourse_cosmetics_store/mission_claim"
  require_relative "app/models/discourse_cosmetics_store/favorite"
  require_relative "app/models/discourse_cosmetics_store/orb_package"
  require_relative "app/models/discourse_cosmetics_store/payment"
  require_relative "app/models/discourse_cosmetics_store/payment_refund"
  require_relative "app/models/discourse_cosmetics_store/payment_event"
  require_relative "lib/discourse_cosmetics_store/catalog"
  require_relative "lib/discourse_cosmetics_store/item_access_extension"
  require_relative "lib/discourse_cosmetics_store/entitlement_provider"
  require_relative "lib/discourse_cosmetics_store/wallet_service"
  require_relative "lib/discourse_cosmetics_store/purchase_service"
  require_relative "lib/discourse_cosmetics_store/gift_service"
  require_relative "lib/discourse_cosmetics_store/mission_progress"
  require_relative "lib/discourse_cosmetics_store/mission_claim_service"
  require_relative "lib/discourse_cosmetics_store/payment_http"
  require_relative "lib/discourse_cosmetics_store/payment_providers"
  require_relative "lib/discourse_cosmetics_store/payment_service"
  require_relative "lib/discourse_cosmetics_store/payment_fulfillment_service"
  require_relative "lib/discourse_cosmetics_store/payment_refund_service"
  require_relative "lib/discourse_cosmetics_store/payment_event_service"
  require_relative "lib/discourse_cosmetics_store/seeder"
  require_relative "app/controllers/discourse_cosmetics_store/store_controller"
  require_relative "app/controllers/discourse_cosmetics_store/inventory_controller"
  require_relative "app/controllers/discourse_cosmetics_store/loadouts_controller"
  require_relative "app/controllers/discourse_cosmetics_store/preview_controller"
  require_relative "app/controllers/discourse_cosmetics_store/admin_controller"
  require_relative "app/controllers/discourse_cosmetics_store/payments_controller"
  require_relative "app/controllers/discourse_cosmetics_store/payment_callbacks_controller"

  unless DiscourseCosmeticsStore.install_cosmetics_integration!
    Rails.logger.error(
      "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] #{DiscourseCosmeticsStore::BASE_PLUGIN_NAME} " \
        "is missing or could not be loaded. The store will stay unavailable until the dependency is fixed.",
    )
  end

  # Try once more after Rails finishes preparing application classes. Both the
  # public provider registration and the legacy prepend fallback are idempotent.
  Rails.application.reloader.to_prepare do
    DiscourseCosmeticsStore.install_cosmetics_integration!
  end

  add_admin_route(
    "discourse_cosmetics_store.admin.title",
    DiscourseCosmeticsStore::PLUGIN_NAME,
    { use_new_show_route: true },
  )

  Discourse::Application.routes.append do
    get "/store" => "list#latest"
    get "/store/browse" => "list#latest"
    get "/store/browse/:category" => "list#latest",
        constraints: { category: /avatar-frames|nameplates|card-decorations|profile-effects|bundles|items/ }
    get "/store/orbs" => "list#latest"
    get "/store/favorites" => "list#latest"
    get "/store/inventory" => "list#latest"
    get "/store/loadouts" => "list#latest"
    get "/store/preview" => "list#latest"
    get "/store/collections" => "list#latest"
    get "/store/collections/:collection_slug" => "list#latest",
        constraints: { collection_slug: /[a-z0-9][a-z0-9\-]*/ }

    defaults format: :json do
      get "/cosmetics-store" => "discourse_cosmetics_store/store#index"
      get "/cosmetics-store/inventory" => "discourse_cosmetics_store/inventory#index"
      get "/cosmetics-store/loadouts" => "discourse_cosmetics_store/loadouts#index"
      post "/cosmetics-store/loadouts" => "discourse_cosmetics_store/loadouts#create"
      put "/cosmetics-store/loadouts/:id" => "discourse_cosmetics_store/loadouts#update",
          constraints: { id: /\d+/ }
      delete "/cosmetics-store/loadouts/:id" => "discourse_cosmetics_store/loadouts#destroy",
             constraints: { id: /\d+/ }
      post "/cosmetics-store/loadouts/:id/apply" => "discourse_cosmetics_store/loadouts#apply",
           constraints: { id: /\d+/ }
      get "/cosmetics-store/preview" => "discourse_cosmetics_store/preview#index"
      post "/cosmetics-store/preview/apply" => "discourse_cosmetics_store/preview#apply"
      post "/cosmetics-store/products/:id/purchase" => "discourse_cosmetics_store/store#purchase",
           constraints: { id: /\d+/ }
      post "/cosmetics-store/products/:id/gift" => "discourse_cosmetics_store/store#gift",
           constraints: { id: /\d+/ }
      put "/cosmetics-store/products/:id/favorite" => "discourse_cosmetics_store/store#favorite",
          constraints: { id: /\d+/ }
      delete "/cosmetics-store/products/:id/favorite" => "discourse_cosmetics_store/store#unfavorite",
             constraints: { id: /\d+/ }
      post "/cosmetics-store/missions/:id/claim" => "discourse_cosmetics_store/store#claim_mission",
           constraints: { id: /\d+/ }
      post "/cosmetics-store/payments" => "discourse_cosmetics_store/payments#create"
      get "/cosmetics-store/payments/:payment_token/status" => "discourse_cosmetics_store/payments#status",
          constraints: { payment_token: /[0-9a-f]{48}/ }
      get "/cosmetics-store/payments/:payment_token/return" => "discourse_cosmetics_store/payments#return_from_provider",
          constraints: { payment_token: /[0-9a-f]{48}/ }
      post "/cosmetics-store/webhooks/:provider" => "discourse_cosmetics_store/payment_callbacks#webhook",
           constraints: { provider: /stripe|paypal|shopier/ }
      post "/cosmetics-store/callbacks/:provider" => "discourse_cosmetics_store/payment_callbacks#callback",
           constraints: { provider: /paytr|iyzico|shipy|shopier-osb/ }

      scope "/admin/plugins/user-cosmetics-store", constraints: AdminConstraint.new do
        get "/catalog" => "discourse_cosmetics_store/admin#index"
        post "/products" => "discourse_cosmetics_store/admin#create_product"
        put "/products/:id" => "discourse_cosmetics_store/admin#update_product",
            constraints: { id: /\d+/ }
        delete "/products/:id" => "discourse_cosmetics_store/admin#destroy_product",
               constraints: { id: /\d+/ }
        post "/missions" => "discourse_cosmetics_store/admin#create_mission"
        put "/missions/:id" => "discourse_cosmetics_store/admin#update_mission",
            constraints: { id: /\d+/ }
        delete "/missions/:id" => "discourse_cosmetics_store/admin#destroy_mission",
               constraints: { id: /\d+/ }
        get "/wallet" => "discourse_cosmetics_store/admin#wallet"
        post "/wallet/adjust" => "discourse_cosmetics_store/admin#adjust_wallet"
        post "/orb-packages" => "discourse_cosmetics_store/admin#create_orb_package"
        put "/orb-packages/:id" => "discourse_cosmetics_store/admin#update_orb_package",
            constraints: { id: /\d+/ }
        delete "/orb-packages/:id" => "discourse_cosmetics_store/admin#destroy_orb_package",
               constraints: { id: /\d+/ }
        post "/payments/:payment_token/refund" => "discourse_cosmetics_store/admin#refund_payment",
             constraints: { payment_token: /[0-9a-f]{48}/ }
      end
    end
  end

  DiscourseCosmeticsStore::Seeder.seed_defaults!
end
