import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import CosmeticsStoreFavoritesPage from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-favorites-page";

module("Component | CosmeticsStoreFavoritesPage", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.deletedFavoriteId = null;
    pretender.delete("/cosmetics-store/products/:id/favorite.json", (request) => {
      this.deletedFavoriteId = Number(request.params.id);
      return response({ favorite: false });
    });

    const product = (attributes) => ({
      id: attributes.id,
      name: attributes.name,
      description: attributes.description || "",
      product_type: attributes.product_type || "item",
      item_count: 1,
      price: attributes.price || 20,
      card_image_url: null,
      hero_image_url: null,
      preview_background_url: null,
      rarity_label: attributes.rarity_label || "Rare",
      tags: attributes.tags || [],
      kinds: attributes.kinds || ["avatar_frame"],
      items: [
        {
          id: attributes.id * 10,
          name: `${attributes.name} item`,
          kind: "avatar_frame",
          kind_label: "Avatar frame",
          image_url: null,
        },
      ],
      featured: false,
      editor_pick: false,
      sort_order: attributes.id,
      purchase_count: 0,
      popularity_score: attributes.popularity_score || 0,
      purchased: false,
      owned: attributes.owned || false,
      favorite: attributes.favorite,
      favoriteable: true,
      giftable: true,
      purchasable: true,
      availability_type: "standard",
      sale_state: "active",
      created_at: attributes.created_at || "2026-08-01T00:00:00Z",
    });

    this.model = {
      products: [
        product({
          id: 1,
          name: "Gold Frame",
          favorite: true,
          rarity_label: "Legendary",
          tags: ["gold"],
          popularity_score: 30,
        }),
        product({
          id: 2,
          name: "Night Frame",
          favorite: true,
          tags: ["night"],
          popularity_score: 20,
        }),
        product({ id: 3, name: "Blue Frame", favorite: false }),
      ],
      filters: {
        kinds: [{ value: "avatar_frame", label: "Avatar frames", count: 3 }],
        rarities: [
          { value: "Legendary", label: "Legendary", count: 1 },
          { value: "Rare", label: "Rare", count: 2 },
        ],
        availability: [],
        tags: [
          { value: "gold", label: "gold", count: 1 },
          { value: "night", label: "night", count: 1 },
        ],
      },
      viewer: {
        logged_in: true,
        favorites_enabled: true,
        preview_user: { username: "tester", avatar_template: "" },
      },
      settings: {
        currency_symbol: "◈",
        hover_preview: false,
      },
      wallet: { balance: 100, debt: 0 },
    };
  });

  test("shows favorites with native navigation and reset controls", async function (assert) {
    await renderFavorites(this);

    assert.dom("[data-testid='favorites-nav-featured']").hasClass("btn");
    assert.dom("[data-testid='favorites-nav-current']").hasClass("btn");
    assert.dom("[data-testid='favorites-nav-current']").hasAria("pressed", "true");
    assert.dom("[data-testid='favorites-balance']").includesText("100");
    assert.dom(".cstore-product").exists({ count: 2 });
    assert.dom(".cstore-results").doesNotIncludeText("Blue Frame");

    await fillIn('.cstore-filters input[type="search"]', "gold");

    assert.dom(".cstore-product").exists({ count: 1 });
    assert.dom(".cstore-results").includesText("Gold Frame");
    assert.dom(".cstore-results").doesNotIncludeText("Night Frame");
    assert.dom(".cstore-favorites-center__active-count").includesText("1");
    assert.dom("[data-testid='favorites-filter-reset']").hasClass("btn");

    await click("[data-testid='favorites-filter-reset']");
    assert.dom(".cstore-product").exists({ count: 2 });
  });

  test("removing a favorite immediately removes it from the saved set", async function (assert) {
    await renderFavorites(this);

    await click(".cstore-product:first-child .cstore-favorite");

    assert.strictEqual(this.deletedFavoriteId, 1);
    assert.dom(".cstore-product").exists({ count: 1 });
    assert.dom(".cstore-results").doesNotIncludeText("Gold Frame");
    assert.dom(".cstore-results").includesText("Night Frame");
  });

  test("uses the native sign-in action for logged-out viewers", async function (assert) {
    this.model = {
      ...this.model,
      viewer: {
        ...this.model.viewer,
        logged_in: false,
      },
    };

    await renderFavorites(this);

    assert
      .dom("a[href='/login?return_path=%2Fstore%2Ffavorites']")
      .hasClass("btn-primary");
    assert.dom("[data-testid='favorites-login']").exists();
    assert.dom(".cstore-product").doesNotExist();
  });
});

async function renderFavorites(context) {
  await render(
    <template><CosmeticsStoreFavoritesPage @model={{context.model}} /></template>
  );
}
