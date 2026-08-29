import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreLoadouts from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-loadouts";

module("Component | CosmeticsStoreLoadouts", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = { logged_in: true };
    this.loadouts = [
      {
        id: 7,
        name: "Night set",
        can_apply: true,
        slots: {
          avatar_frame: {
            item_id: 11,
            available: true,
            item: { id: 11, name: "Night Frame", kind: "avatar_frame" },
          },
          nameplate: { item_id: null, available: true, item: null },
          card_decoration: { item_id: null, available: true, item: null },
          profile_effect: { item_id: null, available: true, item: null },
        },
      },
      {
        id: 8,
        name: "Old set",
        can_apply: false,
        slots: {
          avatar_frame: {
            item_id: 22,
            available: false,
            item: { id: 22, name: "Expired Frame", kind: "avatar_frame" },
          },
          nameplate: { item_id: null, available: true, item: null },
          card_decoration: { item_id: null, available: true, item: null },
          profile_effect: { item_id: null, available: true, item: null },
        },
      },
    ];
  });

  test("renders server-provided slots and disables unavailable sets", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreLoadouts
          @loadouts={{this.loadouts}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("[data-testid='loadout-count']").hasText("2 / 10 sets");
    assert.dom("[data-loadout-id='7'] [data-slot-kind='avatar_frame']").includesText("Night Frame");
    assert.dom("[data-loadout-id='7'] [data-testid='apply-loadout']").isEnabled();
    assert.dom("[data-loadout-id='8']").hasClass("is-unavailable");
    assert.dom("[data-loadout-id='8'] [data-testid='apply-loadout']").isDisabled();
    assert
      .dom("[data-loadout-id='8'] [data-slot-kind='avatar_frame']")
      .hasClass("is-unavailable");
  });

  test("keeps create disabled until a name is entered and opens inline rename", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreLoadouts
          @loadouts={{this.loadouts}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("[data-testid='create-loadout']").isDisabled();
    await fillIn("[data-testid='loadout-name-input']", "Weekend");
    assert.dom("[data-testid='create-loadout']").isEnabled();

    await click("[data-loadout-id='7'] [data-testid='rename-loadout']");
    assert.dom("[data-loadout-id='7'] [data-testid='rename-loadout-input']").hasValue("Night set");
  });
});
