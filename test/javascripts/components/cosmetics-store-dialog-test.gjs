import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreDialog from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-dialog";

module("Component | cosmetics store dialog", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.product = {
      id: 42,
      name: "Ölülerin Efendisi (Mavi)",
      description: "Avatar çerçevesi",
      product_type: "item",
      price: 1150,
      rarity_label: "Yeni",
      sale_state: "active",
      purchasable: true,
      giftable: true,
      owned: false,
      items: [],
      tags: [],
    };

    this.viewer = {
      logged_in: true,
      preview_user: {
        name: "ErespawN",
        username: "ErespawN",
      },
    };

    this.settings = { currency_symbol: "◈" };
    this.purchaseCalls = [];
    this.giftCalls = [];
    this.closed = false;
    this.purchase = (product) => this.purchaseCalls.push(product.id);
    this.gift = (product, username) => {
      this.giftCalls.push([product.id, username]);
    };
    this.close = () => {
      this.closed = true;
    };
  });

  test("uses Discourse DModal instead of a custom dialog shell", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreDialog
          @product={{this.product}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @balance={{3744}}
          @busy={{false}}
          @giftBusy={{false}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
          @onClose={{this.close}}
        />
      </template>
    );

    assert.dom(".d-modal.cstore-dialog").exists();
    assert.dom(".d-modal__title-text").hasText("Ölülerin Efendisi (Mavi)");
    assert.dom(".cstore-dialog__backdrop").doesNotExist();
    assert.dom(".cstore-dialog__close").doesNotExist();
    assert.dom(".cstore-dialog__purchase").exists();

    await click(".cstore-buy");

    assert.deepEqual(this.purchaseCalls, [42]);
  });

  test("gift flow uses FormKit validation and normalizes the recipient", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreDialog
          @product={{this.product}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @balance={{3744}}
          @busy={{false}}
          @giftBusy={{false}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
          @onClose={{this.close}}
        />
      </template>
    );

    await click(".cstore-gift-toggle");

    assert.dom(".cstore-gift-formkit").exists();
    assert.dom(".cstore-gift-formkit input").exists();

    await fillIn(".cstore-gift-formkit input", "  @gift-user  ");
    await click(".cstore-gift-formkit .btn-primary");

    assert.deepEqual(this.giftCalls, [[42, "gift-user"]]);
  });
});
