import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStore from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store";
import CosmeticsStoreFavoritesPage from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-favorites-page";

module("Component | cosmetics store responsive filters", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.storeModel = {
      route_tab: "browse",
      route_filter: null,
      products: [],
      missions: [],
      filters: {
        kinds: [],
        rarities: [],
        availability: [],
        tags: [],
      },
      sections: {},
      settings: {
        currency_symbol: "◈",
        hover_preview: false,
      },
      wallet: {
        balance: 100,
        debt: 0,
        lifetime_earned: 0,
        lifetime_spent: 0,
        ledger: [],
      },
      viewer: {
        logged_in: false,
        favorites_enabled: false,
        preview_user: {},
      },
      orb_packages: [],
      payment_providers: [],
      payments: [],
      collections: [],
    };

    this.favoritesModel = {
      products: [
        {
          id: 1,
          name: "Gold Frame",
          description: "",
          product_type: "item",
          item_count: 1,
          price: 20,
          card_image_url: null,
          hero_image_url: null,
          preview_background_url: null,
          rarity_label: "Rare",
          tags: [],
          kinds: ["avatar_frame"],
          items: [],
          featured: false,
          editor_pick: false,
          sort_order: 1,
          purchase_count: 0,
          popularity_score: 0,
          purchased: false,
          owned: false,
          favorite: true,
          favoriteable: true,
          giftable: false,
          purchasable: false,
          availability_type: "standard",
          sale_state: "active",
          created_at: "2026-08-01T00:00:00Z",
        },
      ],
      filters: {
        kinds: [],
        rarities: [],
        availability: [],
        tags: [],
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

  test("browse filter disclosure exposes expanded state", async function (assert) {
    await render(<template><CosmeticsStore @model={{this.storeModel}} /></template>);

    assert.dom("[data-testid='browse-filter-toggle']").hasAttribute("aria-expanded", "false");
    assert.dom(".cstore-filters").doesNotHaveClass("is-open");

    await click("[data-testid='browse-filter-toggle']");

    assert.dom("[data-testid='browse-filter-toggle']").hasAttribute("aria-expanded", "true");
    assert.dom(".cstore-filters").hasClass("is-open");
  });

  test("favorites filter disclosure uses the same compact interaction", async function (assert) {
    await render(
      <template><CosmeticsStoreFavoritesPage @model={{this.favoritesModel}} /></template>
    );

    assert
      .dom("[data-testid='favorites-filter-toggle']")
      .hasAttribute("aria-expanded", "false");

    await click("[data-testid='favorites-filter-toggle']");

    assert
      .dom("[data-testid='favorites-filter-toggle']")
      .hasAttribute("aria-expanded", "true");
    assert.dom(".cstore-filters").hasClass("is-open");
  });
});
