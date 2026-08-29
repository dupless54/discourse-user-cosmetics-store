import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreHistory from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-history";

module("Component | CosmeticsStoreHistory", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = { logged_in: true };
    this.history = {
      currency_symbol: "◆",
      limits: {
        purchases: 100,
        gifts_sent: 100,
        gifts_received: 100,
      },
      stats: {
        purchase_count: 1,
        gifts_sent_count: 1,
        gifts_received_count: 1,
      },
      purchases: [
        {
          id: 1,
          price_paid: 120,
          status: "completed",
          created_at: "2026-08-28T12:00:00Z",
          product: { id: 10, name: "Owned Frame" },
        },
      ],
      gifts_sent: [
        {
          id: 2,
          direction: "sent",
          price_paid: 240,
          status: "completed",
          created_at: "2026-08-28T13:00:00Z",
          product: { id: 20, name: "Sent Plate" },
          user: { username: "bob", path: "/u/bob" },
        },
      ],
      gifts_received: [
        {
          id: 3,
          direction: "received",
          price_paid: 360,
          status: "refunded",
          created_at: "2026-08-28T14:00:00Z",
          product: { id: 30, name: "Received Card" },
          user: { username: "carol", path: "/u/carol" },
        },
      ],
    };
  });

  test("switches between purchase and gift history without mixing records", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreHistory
          @history={{this.history}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("[data-testid='history-purchase-count'] strong").hasText("1");
    assert.dom("[data-testid='history-entry']").hasTextContaining("Owned Frame");
    assert.dom("[data-testid='history-entry']").doesNotHaveTextContaining("Sent Plate");

    await click("[data-testid='history-tab-gifts_sent']");

    assert.dom("[data-testid='history-entry']").hasTextContaining("Sent Plate");
    assert.dom("[data-testid='history-entry']").hasTextContaining("bob");
    assert.dom("[data-testid='history-entry']").doesNotHaveTextContaining("Owned Frame");

    await click("[data-testid='history-tab-gifts_received']");

    assert.dom("[data-testid='history-entry']").hasTextContaining("Received Card");
    assert.dom("[data-testid='history-entry']").hasTextContaining("carol");
  });

  test("shows the private login state to anonymous visitors", async function (assert) {
    this.viewer = { logged_in: false };
    this.history = {
      purchases: [],
      gifts_sent: [],
      gifts_received: [],
      stats: {
        purchase_count: 0,
        gifts_sent_count: 0,
        gifts_received_count: 0,
      },
    };

    await render(
      <template>
        <CosmeticsStoreHistory
          @history={{this.history}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("a[href*='/login?return_path=%2Fstore%2Fhistory']").exists();
    assert.dom("[data-testid='history-entry']").doesNotExist();
  });
});
