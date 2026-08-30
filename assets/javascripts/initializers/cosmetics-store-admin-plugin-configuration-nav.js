import { withPluginApi } from "discourse/lib/plugin-api";
import CosmeticsStoreAdminSupportBanner from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-admin-support-banner";

const PLUGIN_ID = "discourse-user-cosmetics-store";

export default {
  name: "cosmetics-store-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "discourse_cosmetics_store.admin.overview",
          route: "adminPlugins.show.cosmetics-store-catalog",
          description: "discourse_cosmetics_store.admin.overview_description",
        },
        {
          label: "discourse_cosmetics_store.admin.products",
          route: "adminPlugins.show.cosmetics-store-products",
          description: "discourse_cosmetics_store.admin.products_description",
        },
        {
          label: "discourse_cosmetics_store.admin.missions",
          route: "adminPlugins.show.cosmetics-store-missions",
          description: "discourse_cosmetics_store.admin.missions_description",
        },
        {
          label: "discourse_cosmetics_store.admin.payments",
          route: "adminPlugins.show.cosmetics-store-payments",
          description: "discourse_cosmetics_store.admin.payments_description",
        },
        {
          label: "discourse_cosmetics_store.admin.wallets",
          route: "adminPlugins.show.cosmetics-store-wallets",
          description: "discourse_cosmetics_store.admin.wallets_description",
        },
      ]);
      api.registerPluginHeaderActionComponent(
        PLUGIN_ID,
        CosmeticsStoreAdminSupportBanner
      );
    });
  },
};
