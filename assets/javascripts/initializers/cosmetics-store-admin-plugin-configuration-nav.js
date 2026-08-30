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

    withPluginApi("1.1.0", (api) => {
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "discourse_cosmetics_store.admin.catalog",
          route: "adminPlugins.show.cosmetics-store-catalog",
          description: "discourse_cosmetics_store.admin.catalog_description",
        },
      ]);
      api.registerPluginHeaderActionComponent(
        PLUGIN_ID,
        CosmeticsStoreAdminSupportBanner
      );
    });
  },
};
