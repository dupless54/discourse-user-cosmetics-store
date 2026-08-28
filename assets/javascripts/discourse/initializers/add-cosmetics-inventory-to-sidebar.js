import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "add-cosmetics-inventory-to-sidebar",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const currentUser = container.lookup("service:current-user");

    if (!currentUser || !siteSettings.discourse_cosmetics_store_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addCommunitySectionLink((baseSectionLink) => {
        return class CosmeticsInventorySectionLink extends baseSectionLink {
          name = "cosmetics-inventory";
          route = "cosmetics-store-inventory";
          text = i18n("discourse_cosmetics_store.nav.inventory");
          title = i18n("discourse_cosmetics_store.inventory.subtitle");
          defaultPrefixValue = "image";
        };
      });

      api.addCommunitySectionLink((baseSectionLink) => {
        return class CosmeticsLoadoutsSectionLink extends baseSectionLink {
          name = "cosmetics-loadouts";
          route = "cosmetics-store-loadouts";
          text = i18n("discourse_cosmetics_store.nav.loadouts");
          title = i18n("discourse_cosmetics_store.loadouts.subtitle");
          defaultPrefixValue = "check";
        };
      });

      api.addCommunitySectionLink((baseSectionLink) => {
        return class CosmeticsPreviewSectionLink extends baseSectionLink {
          name = "cosmetics-preview";
          route = "cosmetics-store-preview";
          text = i18n("discourse_cosmetics_store.nav.preview");
          title = i18n("discourse_cosmetics_store.preview.subtitle");
          defaultPrefixValue = "palette";
        };
      });
    });
  },
};
