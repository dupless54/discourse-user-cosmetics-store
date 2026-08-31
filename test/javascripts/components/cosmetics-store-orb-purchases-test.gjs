import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreOrbPurchases from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-orb-purchases";

module("Component | CosmeticsStoreOrbPurchases", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.packages = [
      {
        id: 7,
        name: "Starter",
        description: "Starter package",
        orb_amount: 500,
        price: "4.99",
        currency: "EUR",
        featured: true,
        providers: ["shopier", "stripe"],
      },
    ];
    this.providers = [
      {
        id: "shopier",
        label: "Shopier",
        requires_billing: false,
        requires_identity: false,
      },
      {
        id: "stripe",
        label: "Stripe",
        requires_billing: false,
        requires_identity: false,
      },
    ];
    this.viewer = { logged_in: true, is_admin: false };
    this.settings = { currency_symbol: "◈", currency_name: "SeninCoin" };
  });

  test("opens checkout in native DModal and keeps provider controls interactive", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreOrbPurchases
          @packages={{this.packages}}
          @providers={{this.providers}}
          @payments={{array}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @inline={{true}}
        />
      </template>
    );

    await click("[data-testid='orb-package-open']");

    assert.dom(".d-modal.cstore-payment-dialog").exists();
    assert.dom(".cstore-payment-dialog__backdrop").doesNotExist();
    assert.dom(".cstore-payment-dialog__close").doesNotExist();
    assert.dom("[data-testid='payment-provider']").exists({ count: 2 });
    assert.dom("[data-testid='payment-provider']:first-child").hasAria("pressed", "true");
    assert.dom("[data-testid='payment-submit']").isEnabled();

    await click("[data-testid='payment-provider']:last-child");

    assert.dom("[data-testid='payment-provider']:last-child").hasAria("pressed", "true");
    assert.dom("[data-testid='payment-provider']:first-child").hasAria("pressed", "false");
  });
});
