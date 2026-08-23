# frozen_string_literal: true

# name: discourse-user-cosmetics-store
# about: Discord tarzı Orbs mağazası, görevler ve discourse-user-cosmetics entegrasyonu.
# version: 1.0.0
# authors: dupless54
# url: https://forum.senin.me/store
# required_version: 3.3.0

enabled_site_setting :discourse_cosmetics_store_enabled

register_asset "stylesheets/discourse-cosmetics-store.scss"

module ::DiscourseCosmeticsStore
  PLUGIN_NAME = "discourse-user-cosmetics-store"
end

after_initialize do
  unless defined?(::DiscourseUserCosmetics::Item)
    raise "#{DiscourseCosmeticsStore::PLUGIN_NAME} requires discourse-user-cosmetics"
  end

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

  ::DiscourseUserCosmetics::Item.prepend(::DiscourseCosmeticsStore::ItemAccessExtension)

  add_admin_route "discourse_cosmetics_store.admin.title", "user-cosmetics-store"

  Discourse::Application.routes.append do
    get "/store" => "list#latest"
    get "/admin/plugins/user-cosmetics-store" => "admin/plugins#index",
        constraints: StaffConstraint.new

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
