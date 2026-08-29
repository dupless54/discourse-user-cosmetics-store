import Service from "@ember/service";
import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreAdminSupportBanner from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-admin-support-banner";

module("Component | CosmeticsStoreAdminSupportBanner", function (hooks) {
  setupRenderingTest(hooks);

  test("shows the Buy Me a Coffee banner on plugin settings", async function (assert) {
    class RouterStub extends Service {
      currentRouteName = "adminPlugins.show.settings";
    }

    this.owner.register("service:router", RouterStub);

    await render(
      <template><CosmeticsStoreAdminSupportBanner /></template>
    );

    assert
      .dom(".cstore-admin-support-banner")
      .hasAttribute("href", "https://buymeacoffee.com/erespawn");
    assert
      .dom(".cstore-admin-support-banner img")
      .hasAttribute(
        "src",
        "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
      );
    assert.dom(".cstore-admin-support-banner img").hasAttribute("alt", "Buy Me a Coffee");
  });

  test("does not show the banner on the custom catalog tab", async function (assert) {
    class RouterStub extends Service {
      currentRouteName = "adminPlugins.show.cosmetics-store-catalog";
    }

    this.owner.register("service:router", RouterStub);

    await render(
      <template><CosmeticsStoreAdminSupportBanner /></template>
    );

    assert.dom(".cstore-admin-support-banner").doesNotExist();
  });
});
