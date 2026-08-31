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
        requires_billing: true,
        requires_identity: true,
      },
      {
        id: "stripe",
        label: "Stripe",
        requires_billing: false,
        requires_identity: false,
      },
    ];
    this.payments = [];
    this.viewer = { logged_in: true, is_admin: false };
    this.settings = { currency_symbol: "◈", currency_name: "SeninCoin" };
  });

  test("opens localized checkout in native DModal and keeps provider controls interactive", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreOrbPurchases
          @packages={{this.packages}}
          @providers={{this.providers}}
          @payments={{this.payments}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @inline={{true}}
        />
      </template>
    );

    assert.dom(".cstore-section__heading").includesText("SECURE PAYMENT");
    assert.dom(".cstore-section__heading").includesText("Top up SeninCoin");
    assert.dom("[data-testid='orb-package-open']").hasClass("btn");
    assert.dom("[data-testid='orb-package-open']").includesText("Top up for 4.99 EUR");
    assert.dom(".cstore-cash-packages__badge").hasText("RECOMMENDED");

    await click("[data-testid='orb-package-open']");

    assert.dom(".d-modal.cstore-payment-dialog").exists();
    assert.dom(".cstore-payment-dialog__backdrop").doesNotExist();
    assert.dom(".cstore-payment-dialog__close").doesNotExist();
    assert.dom(".cstore-payment-dialog__window").includesText("Payment method");
    assert.dom(".cstore-payment-billing").includesText("Billing details required by the provider");
    assert.dom(".cstore-payment-billing").includesText("Full name");
    assert.dom(".cstore-payment-billing").includesText("Identity number");
    assert
      .dom(".cstore-payment-dialog__notice")
      .includesText("revalidated on the server");
    assert.dom("[data-testid='payment-provider']").exists({ count: 2 });
    assert.dom("[data-testid='payment-provider']:first-child").hasClass("btn");
    assert.dom("[data-testid='payment-provider']:first-child").hasClass("is-active");
    assert
      .dom("[data-testid='payment-provider']:first-child")
      .hasAttribute("aria-pressed", "true");
    assert.dom("[data-testid='payment-provider']:last-child").doesNotHaveClass("is-active");
    assert
      .dom("[data-testid='payment-provider']:last-child")
      .hasAttribute("aria-pressed", "false");
    assert.dom("[data-testid='payment-submit']").hasClass("btn");
    assert.dom("[data-testid='payment-submit']").hasAttribute("type", "submit");
    assert.dom("[data-testid='payment-submit']").hasText("Continue to payment");
    assert.dom("[data-testid='payment-submit']").isEnabled();

    await click("[data-testid='payment-provider']:last-child");

    assert.dom("[data-testid='payment-provider']:last-child").hasClass("is-active");
    assert
      .dom("[data-testid='payment-provider']:last-child")
      .hasAttribute("aria-pressed", "true");
    assert.dom("[data-testid='payment-provider']:first-child").doesNotHaveClass("is-active");
    assert
      .dom("[data-testid='payment-provider']:first-child")
      .hasAttribute("aria-pressed", "false");
    assert.dom(".cstore-payment-billing").doesNotExist();
  });
});
