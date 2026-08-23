# frozen_string_literal: true

# name: discourse-user-cosmetics-store
# about: Discord tarzı Orbs mağazası, görevler ve discourse-user-cosmetics entegrasyonu.
# version: 1.0.3
# authors: dupless54
# url: https://forum.senin.me/store
# required_version: 3.3.0

enabled_site_setting :discourse_cosmetics_store_enabled

register_asset "stylesheets/discourse-cosmetics-store.scss"

module ::DiscourseCosmeticsStore
  PLUGIN_NAME = "discourse-user-cosmetics-store"
  BASE_PLUGIN_NAME = "discourse-user-cosmetics"
  BASE_PLUGIN_RUBY_FILES = %w[
    app/models/discourse_user_cosmetics/item.rb
    app/models/discourse_user_cosmetics/item_group.rb
    app/models/discourse_user_cosmetics/user_item.rb
    app/models/discourse_user_cosmetics/user_selection.rb
    app/models/discourse_user_cosmetics/effect_layer.rb
    lib/discourse_user_cosmetics/presenter.rb
  ].freeze

  def self.base_plugin_ready?
    defined?(::DiscourseUserCosmetics::Item) &&
      defined?(::DiscourseUserCosmetics::UserItem) &&
      defined?(::DiscourseUserCosmetics::UserSelection) &&
      defined?(::DiscourseUserCosmetics::Presenter)
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
  # callback order.
  def self.load_base_plugin!
    return true if base_plugin_ready?
    return false unless defined?(::DiscourseUserCosmetics)

    root = base_plugin_root
    return false unless File.directory?(root)

    BASE_PLUGIN_RUBY_FILES.each do |relative_path|
      absolute_path = File.join(root, relative_path)
      return false unless File.file?(absolute_path)

      require absolute_path
    end

    base_plugin_ready?
  rescue StandardError, LoadError => error
    Rails.logger.error(
      "[#{PLUGIN_NAME}] could not load #{BASE_PLUGIN_NAME}: " \
        "#{error.class}: #{error.message}",
    )
    false
  end

  def self.install_item_access_extension!
    return false unless load_base_plugin!
    return true if ::DiscourseUserCosmetics::Item < ItemAccessExtension

    ::DiscourseUserCosmetics::Item.prepend(ItemAccessExtension)
    true
  end
end

after_initialize do
  require_relative "app/models/discourse_cosmetics_store/product"
  require_relative "app/models/discourse_cosmetics_store/product_item"
  require_relative "app/models/discourse_cosmetics_store/wallet"
  require_relative "app/models/discourse_cosmetics_store/ledger_entry"
  require_relative "app/models/discourse_cosmetics_store/purchase"
  require_relative "app/models/discourse_cosmetics_store/mission"
  require_relative "app/models/discourse_cosmetics_store/mission_claim"
  require_relative "app/models/discourse_cosmetics_store/favorite"
  require_relative "lib/discourse_cosmetics_store/catalog"
  require_relative "lib/discourse_cosmetics_store/item_access_extension"
  require_relative "lib/discourse_cosmetics_store/wallet_service"
  require_relative "lib/discourse_cosmetics_store/purchase_service"
  require_relative "lib/discourse_cosmetics_store/mission_progress"
  require_relative "lib/discourse_cosmetics_store/mission_claim_service"
  require_relative "lib/discourse_cosmetics_store/seeder"
  require_relative "app/controllers/discourse_cosmetics_store/store_controller"
  require_relative "app/controllers/discourse_cosmetics_store/admin_controller"

  unless DiscourseCosmeticsStore.install_item_access_extension!
    Rails.logger.error(
      "[#{DiscourseCosmeticsStore::PLUGIN_NAME}] #{DiscourseCosmeticsStore::BASE_PLUGIN_NAME} " \
        "is missing or could not be loaded. The store will stay unavailable until the dependency is fixed.",
    )
  end

  # Try once more after Rails finishes preparing application classes. This is
  # idempotent and covers installations where plugin callbacks are evaluated in
  # a non-alphabetical order.
  Rails.application.reloader.to_prepare do
    DiscourseCosmeticsStore.install_item_access_extension!
  end

  add_admin_route(
    "discourse_cosmetics_store.admin.title",
    DiscourseCosmeticsStore::PLUGIN_NAME,
    { use_new_show_route: true },
  )

  Discourse::Application.routes.append do
    get "/store" => "list#latest"

    defaults format: :json do
      get "/cosmetics-store" => "discourse_cosmetics_store/store#index"
      post "/cosmetics-store/products/:id/purchase" => "discourse_cosmetics_store/store#purchase",
           constraints: { id: /\d+/ }
      put "/cosmetics-store/products/:id/favorite" => "discourse_cosmetics_store/store#favorite",
          constraints: { id: /\d+/ }
      delete "/cosmetics-store/products/:id/favorite" => "discourse_cosmetics_store/store#unfavorite",
             constraints: { id: /\d+/ }
      post "/cosmetics-store/missions/:id/claim" => "discourse_cosmetics_store/store#claim_mission",
           constraints: { id: /\d+/ }

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
      end
    end
  end

  DiscourseCosmeticsStore::Seeder.seed_defaults!
end
