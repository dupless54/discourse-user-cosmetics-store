import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreProductCard from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-product-card";

module("Component | cosmetics store product card", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.product = {
      id: 7,
      name: "Aurora Frame",
      description: "A cosmetic frame",
      product_type: "item",
      price: 250,
      rarity_label: "Rare",
      sale_state: "active",
      purchasable: true,
      giftable: true,
      favorite: false,
      favoriteable: true,
      editor_pick: true,
      owned: false,
      item_count: 1,
      items: [],
      tags: [],
    };
    this.previewUser = { username: "member" };

    this.openCalls = [];
    this.giftCalls = [];
    this.favoriteCalls = [];
    this.open = (product) => this.openCalls.push(product.id);
    this.gift = (product) => this.giftCalls.push(product.id);
    this.favorite = (product) => this.favoriteCalls.push(product.id);
  });

  test("renders product actions from Discourse client i18n", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreProductCard
          @product={{this.product}}
          @previewUser={{this.previewUser}}
          @currencySymbol="◈"
          @favoritesEnabled={{true}}
          @hoverPreview={{false}}
          @onOpen={{this.open}}
          @onGift={{this.gift}}
          @onFavorite={{this.favorite}}
        />
      </template>
    );

    assert
      .dom(".cstore-product__open")
      .hasAttribute("aria-label", "Open Aurora Frame details");
    assert.dom(".cstore-product__peek").includesText("Live preview");
    assert.dom(".cstore-product__buy").includesText("Buy");
    assert.dom(".cstore-product__meta").includesText("EDITOR'S PICK");
    assert.dom(".cstore-product__info").includesText("Cosmetic · 1 items");
    assert
      .dom(".cstore-favorite")
      .hasAttribute("aria-label", "Add to favorites");
    assert
      .dom(".cstore-product__gift")
      .hasAttribute("aria-label", "Gift Aurora Frame");

    await click(".cstore-product__open");
    await click(".cstore-favorite");
    await click(".cstore-product__gift");

    assert.deepEqual(this.openCalls, [7]);
    assert.deepEqual(this.favoriteCalls, [7]);
    assert.deepEqual(this.giftCalls, [7]);
  });
});
