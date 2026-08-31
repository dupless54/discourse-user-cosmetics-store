import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreActivity from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-activity";

module("Component | CosmeticsStoreActivity", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = { logged_in: true, username: "activity-user" };
    this.activity = {
      wallet: {
        balance: 400,
        debt: 0,
        lifetime_earned: 700,
        lifetime_spent: 300,
      },
      stats: {
        purchases: 1,
        gifts_sent: 0,
        gifts_received: 1,
        orb_events: 1,
      },
      events: [
        {
          id: "purchase:1",
          kind: "purchase",
          status: "completed",
          amount: -100,
          created_at: "2026-08-28T20:00:00Z",
          product: { id: 1, name: "Night Frame", rarity_label: "Epic" },
        },
        {
          id: "gift_received:2",
          kind: "gift_received",
          status: "completed",
          created_at: "2026-08-28T19:00:00Z",
          product: { id: 2, name: "Glow Plate" },
          counterparty: { username: "sender" },
        },
        {
          id: "orb:3",
          kind: "orb",
          entry_type: "mission_reward",
          amount: 25,
          balance_after: 400,
          debt_after: 0,
          created_at: "2026-08-28T18:00:00Z",
        },
      ],
    };
  });

  test("renders the server-provided wallet summary, timeline, and native navigation", async function (assert) {
    await renderActivity(this);

    assert.dom("[data-testid='activity-balance']").hasText("400");
    assert.dom("a[href='/store']").hasClass("btn");
    assert.dom("a[href='/store/inventory']").hasClass("btn");
    assert.dom("[data-event-kind='purchase']").exists();
    assert.dom("[data-event-kind='gift_received']").exists();
    assert.dom("[data-event-kind='orb']").exists();
    assert.dom(".cstore-activity__amount.is-negative").includesText("-100");
    assert.dom(".cstore-activity__amount.is-positive").includesText("+25");
  });

  test("filters gifts and Orb events with native pressed-state semantics", async function (assert) {
    await renderActivity(this);

    assert.dom("[data-testid='activity-filter-all']").hasAria("pressed", "true");
    assert.dom("[data-testid='activity-filter-gifts']").hasAria("pressed", "false");

    await click("[data-testid='activity-filter-gifts']");
    assert.dom("[data-testid='activity-filter-all']").hasAria("pressed", "false");
    assert.dom("[data-testid='activity-filter-gifts']").hasAria("pressed", "true");
    assert.dom("[data-event-kind='gift_received']").exists();
    assert.dom("[data-event-kind='purchase']").doesNotExist();
    assert.dom("[data-event-kind='orb']").doesNotExist();

    await click("[data-testid='activity-filter-orb']");
    assert.dom("[data-testid='activity-filter-gifts']").hasAria("pressed", "false");
    assert.dom("[data-testid='activity-filter-orb']").hasAria("pressed", "true");
    assert.dom("[data-event-kind='orb']").exists();
    assert.dom("[data-event-kind='gift_received']").doesNotExist();
  });

  test("does not render private activity for logged-out viewers", async function (assert) {
    this.viewer = { logged_in: false };

    await renderActivity(this);

    assert.dom("[data-event-kind]").doesNotExist();
    assert
      .dom("a[href='/login?return_path=%2Fstore%2Factivity']")
      .hasClass("btn-primary");
  });
});

async function renderActivity(context) {
  await render(
    <template>
      <CosmeticsStoreActivity
        @activity={{context.activity}}
        @viewer={{context.viewer}}
      />
    </template>
  );
}
