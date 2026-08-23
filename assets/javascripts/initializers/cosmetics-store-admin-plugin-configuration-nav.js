import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "cosmetics-store-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi("1.1.0", (api) => {
      api.addAdminPluginConfigurationNav("discourse-user-cosmetics-store", [
        {
          label: "discourse_cosmetics_store.admin.catalog",
          route: "adminPlugins.show.cosmetics-store-catalog",
          description: "discourse_cosmetics_store.admin.catalog_description",
        },
      ]);
    });
  },
};
