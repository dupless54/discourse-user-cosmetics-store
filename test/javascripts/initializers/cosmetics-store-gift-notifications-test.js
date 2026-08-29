import { module, test } from "qunit";
import { giftNotificationRenderer } from "discourse/plugins/discourse-user-cosmetics-store/discourse/initializers/cosmetics-store-gift-notifications";

class NotificationItemBase {
  constructor({ notification }) {
    this.notification = notification;
  }

  get label() {
    return this.notification.data.display_username;
  }
}

module("Unit | Initializer | cosmetics-store-gift-notifications", function () {
  test("renders a Store gift as a native link to private activity", function (assert) {
    const Renderer = giftNotificationRenderer(NotificationItemBase);
    const renderer = new Renderer({
      notification: {
        data: {
          display_username: "sender",
          product_name: "Golden Frame",
        },
      },
    });

    assert.strictEqual(renderer.linkHref, "/store/activity");
    assert.strictEqual(renderer.icon, "gift");
    assert.strictEqual(renderer.label, "sender");
    assert.true(renderer.linkTitle.length > 0);
    assert.true(renderer.description.includes("Golden Frame"));
  });
});
