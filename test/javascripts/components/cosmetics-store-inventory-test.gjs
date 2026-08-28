import { click, render, select } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import CosmeticsStoreInventory from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-inventory";

module("Component | CosmeticsStoreInventory", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = { logged_in: true, can_manage_selection: true };
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
          equipped: false,
          is_default: false,
        },
        {
          id: 22,
          kind: "nameplate",
          name: "Group Plate",
          description: "Group unlocked cosmetic",
          directly_owned: false,
          unlocked: true,
          equipped: false,
          is_default: false,
        },
      ],
    };
  });

  test("defaults to direct ownership and exposes separate access mode", async function (assert) {
    await renderInventory(this);

    assert.dom("[data-testid='inventory-owned-count'] strong").hasText("1", "owned count is rendered");
    assert.dom("[data-testid='inventory-unlocked-count'] strong").hasText("2", "unlocked count is rendered");
    assert.dom("[data-item-id='11']").exists("directly owned item is shown");
    assert
      .dom("[data-item-id='22']")
      .doesNotExist("access-only item is not misrepresented as owned");

    await click("[data-testid='inventory-mode-unlocked']");

    assert.dom("[data-item-id='11']").exists("owned item remains available");
    assert.dom("[data-item-id='22']").exists("access-only item appears in unlocked mode");
  });

  test("filters the server-provided inventory by cosmetic kind", async function (assert) {
    await renderInventory(this);

    await click("[data-testid='inventory-mode-unlocked']");
    await select("[data-testid='inventory-kind-filter']", "nameplate");

    assert.dom("[data-item-id='11']").doesNotExist("other cosmetic kinds are filtered out");
    assert.dom("[data-item-id='22']").exists("selected cosmetic kind remains visible");
  });

  test("renders server-provided equipped state", async function (assert) {
    this.inventory = {
      ...this.inventory,
      items: this.inventory.items.map((item) => ({
        ...item,
        equipped: item.id === 11,
      })),
    };

    await renderInventory(this);

    assert.dom("[data-item-id='11']").hasClass("is-equipped", "equipped cosmetic is highlighted");
    assert.dom("[data-item-id='11'] [data-testid='unequip-cosmetic']").exists("equipped cosmetic can be removed");
    assert.dom("[data-item-id='11'] [data-testid='equip-cosmetic']").doesNotExist("equipped cosmetic is not offered twice");
  });

  test("quick equip updates the wardrobe without reloading", async function (assert) {
    pretender.put("/cosmetics-store/inventory/11/equip.json", () =>
      response({
        equipped_item_ids: {
          avatar_frame: 11,
          nameplate: null,
          card_decoration: null,
          profile_effect: null,
        },
        message: "Cosmetic equipped.",
      })
    );

    await renderInventory(this);
    await click("[data-item-id='11'] [data-testid='equip-cosmetic']");

    assert.dom("[data-item-id='11']").hasClass("is-equipped", "server-confirmed item becomes equipped");
    assert.dom("[data-item-id='11'] [data-testid='unequip-cosmetic']").exists("action changes to unequip");
    assert.dom("[role='status']").includesText("Owned Frame", "success notice names the equipped item");
  });

  test("unequip updates only the selected kind in the wardrobe", async function (assert) {
    this.inventory = {
      ...this.inventory,
      items: this.inventory.items.map((item) => ({
        ...item,
        equipped: item.id === 11,
      })),
    };
    pretender.delete("/cosmetics-store/inventory/avatar_frame/equip.json", () =>
      response({
        equipped_item_ids: {
          avatar_frame: null,
          nameplate: 22,
          card_decoration: null,
          profile_effect: null,
        },
        message: "Cosmetic unequipped.",
      })
    );

    await renderInventory(this);
    await click("[data-item-id='11'] [data-testid='unequip-cosmetic']");

    assert.dom("[data-item-id='11']").doesNotHaveClass("is-equipped", "removed cosmetic is no longer highlighted");
    assert.dom("[data-item-id='11'] [data-testid='equip-cosmetic']").exists("removed cosmetic can be equipped again");
  });

  test("hides selection actions when the Base contract is unavailable", async function (assert) {
    this.viewer = { logged_in: true, can_manage_selection: false };

    await renderInventory(this);

    assert.dom("[data-testid='equip-cosmetic']").doesNotExist("no client action is exposed without server capability");
    assert.dom("a[href='/my/preferences/cosmetics']").exists("advanced Base settings remain available");
  });
});

async function renderInventory(context) {
  await render(
    <template>
      <CosmeticsStoreInventory
        @inventory={{context.inventory}}
        @viewer={{context.viewer}}
      />
    </template>
  );
}
