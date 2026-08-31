import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreProductForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-product-form";

module("Component | CosmeticsStoreProductForm", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.catalog = {
      products: [],
      cosmetic_items: [
        {
          id: 1,
          kind: "avatar_frame",
          name: "Crimson Frame",
          image_url: null,
          rarity_label: "Epic",
          enabled: true,
        },
        {
          id: 2,
          kind: "avatar_frame",
          name: "Retired Frame",
          image_url: null,
          rarity_label: "Rare",
          enabled: false,
        },
      ],
    };
  });

  test("renders the native FormKit product editor", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreProductForm @catalog={{this.catalog}} @product={{null}} />
      </template>
    );

    assert.dom('input[name="name"]').exists();
    assert.dom('select[name="product_type"]').exists();
    assert.dom('input[name="price"]').exists();
    assert.dom('textarea[name="description"]').exists();
    assert.dom(".cstore-admin-items").exists();
    assert.dom('.cstore-admin-items input[name="cosmetic-item"]').exists({ count: 2 });
    assert.dom('.cstore-admin-items input[name="cosmetic-item"]:disabled').exists({ count: 1 });
    assert.dom(".cstore-admin-form").doesNotExist();
  });
});
