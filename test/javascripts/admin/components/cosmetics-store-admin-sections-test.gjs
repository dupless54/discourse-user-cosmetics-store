import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreMissionsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-missions-admin";
import CosmeticsStoreProductsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-products-admin";
import CosmeticsStoreWalletsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-wallets-admin";

module("Component | Store admin sections", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.model = {
      products: [],
      cosmetic_items: [],
      missions: [],
      mission_metrics: [],
      orb_packages: [],
      payment_providers: [],
      payments: [],
      settings: { currency_name: "Orbs", currency_symbol: "◈" },
    };
  });

  test("products render without the legacy inner admin navigation", async function (assert) {
    await render(
      <template><CosmeticsStoreProductsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-products").exists();
    assert.dom(".cstore-admin__header").doesNotExist();
    assert.dom(".cstore-admin__tabs").doesNotExist();
    assert.dom("table.d-table").exists();
  });

  test("missions render as an independent admin section", async function (assert) {
    await render(
      <template><CosmeticsStoreMissionsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-missions-section").exists();
    assert.dom(".cstore-admin__tabs").doesNotExist();
  });

  test("wallets render as an independent admin section", async function (assert) {
    await render(
      <template><CosmeticsStoreWalletsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-wallets").exists();
    assert.dom(".cstore-admin__tabs").doesNotExist();
  });
});
