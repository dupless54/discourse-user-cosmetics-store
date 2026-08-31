import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreMissionsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-missions-admin";
import CosmeticsStorePaymentsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-payments-admin";
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

  test("products use the native empty-list state without legacy inner navigation", async function (assert) {
    await render(
      <template><CosmeticsStoreProductsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-products").exists();
    assert.dom(".cstore-admin__header").doesNotExist();
    assert.dom(".cstore-admin__tabs").doesNotExist();
    assert.dom(".admin-config-area-empty-list").exists();
    assert.dom("table.d-table").doesNotExist();
  });

  test("products render in the native responsive table when catalogue rows exist", async function (assert) {
    this.model.products = [
      {
        id: 1,
        name: "Crimson Frame",
        slug: "crimson-frame",
        product_type: "item",
        item_names: ["Crimson Frame"],
        price: 250,
        enabled: true,
        editor_pick: false,
        purchase_count: 3,
      },
    ];

    await render(
      <template><CosmeticsStoreProductsAdmin @model={{this.model}} /></template>
    );

    assert.dom("table.d-table").exists();
    assert.dom("tbody.d-table__body tr.d-table__row").exists({ count: 1 });
    assert.dom(".d-table__mobile-label").exists();
    assert.dom(".cstore-admin-form").doesNotExist();
  });

  test("missions use the native empty-list state without legacy inner navigation", async function (assert) {
    await render(
      <template><CosmeticsStoreMissionsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-missions-section").exists();
    assert.dom(".cstore-admin__tabs").doesNotExist();
    assert.dom(".admin-config-area-empty-list").exists();
    assert.dom("table.d-table").doesNotExist();
  });

  test("missions render in the native responsive table when rows exist", async function (assert) {
    this.model.missions = [
      {
        id: 7,
        key: "first-post",
        name: "First post",
        description: "Publish a post.",
        metric: "posts_created",
        target: 1,
        reward: 25,
        icon: "✦",
        enabled: true,
        claim_count: 4,
      },
    ];

    await render(
      <template><CosmeticsStoreMissionsAdmin @model={{this.model}} /></template>
    );

    assert.dom("table.d-table.cstore-admin-missions-table").exists();
    assert.dom("tbody.d-table__body tr.d-table__row").exists({ count: 1 });
    assert.dom(".d-table__mobile-label").exists();
    assert.dom(".cstore-admin-form--mission").doesNotExist();
  });

  test("wallets use a native FormKit lookup without legacy input handlers", async function (assert) {
    await render(
      <template><CosmeticsStoreWalletsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-wallets").exists();
    assert.dom(".cstore-admin__tabs").doesNotExist();
    assert.dom('input[name="username"]').exists();
    assert.dom(".cstore-wallet-search").doesNotExist();
    assert.dom(".cstore-wallet-card").doesNotExist();
  });

  test("payments use native empty states instead of inline editors", async function (assert) {
    await render(
      <template><CosmeticsStorePaymentsAdmin @model={{this.model}} /></template>
    );

    assert.dom(".cstore-admin-payments").exists();
    assert.dom(".admin-config-area-empty-list").exists({ count: 2 });
    assert.dom("table.d-table").doesNotExist();
    assert.dom(".cstore-admin-form").doesNotExist();
    assert.dom("form.cstore-refund-form").doesNotExist();
  });

  test("payments and Orb packages render in native responsive tables", async function (assert) {
    this.model.orb_packages = [
      {
        id: 4,
        name: "Starter Orbs",
        orb_amount: 100,
        price: "49.90",
        currency: "TRY",
        providers: ["shopier"],
        enabled: true,
        payment_count: 2,
      },
    ];
    this.model.payments = [
      {
        token: "payment-1",
        username: "alice",
        package_name: "Starter Orbs",
        provider: "shopier",
        amount: "49.90",
        currency: "TRY",
        refunded_amount_minor: 0,
        refunded_amount: "0.00",
        orb_amount: 100,
        refunded_orb_amount: 0,
        status: "completed",
        failure_message: null,
        refunds: [],
        refundable: true,
      },
    ];

    await render(
      <template><CosmeticsStorePaymentsAdmin @model={{this.model}} /></template>
    );

    assert.dom("table.d-table.cstore-admin-orb-packages-table").exists();
    assert.dom("table.d-table.cstore-admin-payments-table").exists();
    assert.dom("tbody.d-table__body tr.d-table__row").exists({ count: 2 });
    assert.dom(".d-table__mobile-label").exists();
    assert
      .dom(".cstore-admin-payments-table .d-table__cell-actions")
      .doesNotExist();
    assert.dom(".cstore-admin-payments-table .btn-default").exists();
  });
});
