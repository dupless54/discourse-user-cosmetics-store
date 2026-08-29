import getURL from "discourse/lib/get-url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export function giftNotificationRenderer(NotificationItemBase) {
  return class extends NotificationItemBase {
    get linkHref() {
      return getURL("/store/history");
    }

    get linkTitle() {
      return i18n(
        "discourse_cosmetics_store.notifications.gift_received_title"
      );
    }

    get icon() {
      return "gift";
    }

    get description() {
      return i18n(
        "discourse_cosmetics_store.notifications.gift_received_description",
        { product_name: this.notification.data.product_name }
      );
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
