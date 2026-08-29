import { click, render, select } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreInventory from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-inventory";

module("Component | CosmeticsStoreInventory", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = { logged_in: true };
    this.inventory = {
      stats: {
        catalog_count: 3,
        visible_count: 2,
        directly_owned_count: 1,
        unlocked_count: 2,
      },
      kinds: [
        {
          kind: "avatar_frame",
          visible_count: 1,
          directly_owned_count: 1,
          unlocked_count: 1,
        },
        {
          kind: "nameplate",
          visible_count: 1,
          directly_owned_count: 0,
          unlocked_count: 1,
        },
      ],
      items: [
        {
          id: 11,
          kind: "avatar_frame",
          name: "Owned Frame",
          description: "Directly owned cosmetic",
          directly_owned: true,
          unlocked: true,
          is_default: false,
        },
        {
          id: 22,
          kind: "nameplate",
          name: "Group Plate",
          description: "Group unlocked cosmetic",
          directly_owned: false,
          unlocked: true,
          is_default: false,
        },
      ],
    };
  });

  test("defaults to direct ownership and exposes separate access mode", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreInventory
          @inventory={{this.inventory}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("[data-testid='inventory-owned-count'] strong").hasText("1");
    assert.dom("[data-testid='inventory-unlocked-count'] strong").hasText("2");
    assert.dom("[data-item-id='11']").exists("directly owned item is shown");
    assert
      .dom("[data-item-id='22']")
      .doesNotExist("access-only item is not misrepresented as owned");

    await click("[data-testid='inventory-mode-unlocked']");

    assert.dom("[data-item-id='11']").exists();
    assert.dom("[data-item-id='22']").exists("access-only item appears in unlocked mode");
  });

  test("filters the server-provided inventory by cosmetic kind", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreInventory
          @inventory={{this.inventory}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    await click("[data-testid='inventory-mode-unlocked']");
    await select("[data-testid='inventory-kind-filter']", "nameplate");

    assert.dom("[data-item-id='11']").doesNotExist();
    assert.dom("[data-item-id='22']").exists();
  });
});
