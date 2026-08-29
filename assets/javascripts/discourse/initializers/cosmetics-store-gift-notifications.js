import getURL from "discourse/lib/get-url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export function giftNotificationRenderer(NotificationItemBase) {
  return class extends NotificationItemBase {
    get linkHref() {
      return getURL("/store/activity");
    }

    get linkTitle() {
      return i18n("discourse_cosmetics_store.activity.title");
    }

    get icon() {
      return "gift";
    }

    get description() {
      return i18n("discourse_cosmetics_store.activity.events.gift_received", {
        name: this.notification.data.product_name,
        username: this.notification.data.display_username,
      });
    }
  };
}

export default {
  name: "cosmetics-store-gift-notifications",

  initialize() {
    withPluginApi((api) => {
      if (!api.registerNotificationTypeRenderer) {
        return;
      }

      api.registerNotificationTypeRenderer(
        "cosmetics_store_gift",
        giftNotificationRenderer
      );
    });
  },
};
