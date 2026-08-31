import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import {
  CLOSE_INITIATED_BY_BUTTON,
  CLOSE_INITIATED_BY_CLICK_OUTSIDE,
} from "discourse/ui-kit/d-modal";
import CosmeticsStoreDialog, {
  shouldCloseProductModal,
} from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-dialog";

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

  test("uses an isolated Discourse DModal wrapper instead of the legacy dialog shell", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreDialog
          @product={{this.product}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @balance={{3744}}
          @busy={{false}}
          @giftBusy={{false}}
          @inline={{true}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
          @onClose={{this.close}}
        />
      </template>
    );

    assert.dom(".d-modal.cstore-product-modal").exists();
    assert.dom(".d-modal.cstore-dialog").doesNotExist();
    assert.dom(".d-modal__title-text").hasText("Ölülerin Efendisi (Mavi)");
    assert.dom(".cstore-dialog__backdrop").doesNotExist();
    assert.dom(".cstore-dialog__close").doesNotExist();
    assert.dom(".cstore-dialog__purchase").includesText("Price");
    assert.dom(".cstore-gift-toggle").hasText("Gift");
    assert
      .dom(".cstore-dialog__live .cstore-eyebrow")
      .hasText("HOW IT LOOKS ON YOUR PROFILE");

    await click(".cstore-buy");

    assert.deepEqual(this.purchaseCalls, [42]);
  });

  test("blocks click-out dismissal while preserving explicit native dismissal", function (assert) {
    assert.false(
      shouldCloseProductModal({
        initiatedBy: CLOSE_INITIATED_BY_CLICK_OUTSIDE,
      }),
      "clicking outside does not dismiss the product modal"
    );
    assert.true(
      shouldCloseProductModal({ initiatedBy: CLOSE_INITIATED_BY_BUTTON }),
      "the native close button can still dismiss the product modal"
    );
  });

  test("gift flow stays interactive and normalizes the recipient", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreDialog
          @product={{this.product}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @balance={{3744}}
          @busy={{false}}
          @giftBusy={{false}}
          @inline={{true}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
          @onClose={{this.close}}
        />
      </template>
    );

    await click(".cstore-gift-toggle");

    assert.dom(".cstore-gift-panel").exists();
    assert.dom(".cstore-gift-formkit").exists();
    assert.dom(".cstore-gift-formkit input").exists();
    assert.dom(".cstore-gift-formkit").includesText("Gift recipient");
    assert.false(this.closed, "an action inside the modal does not close it");

    await fillIn(".cstore-gift-formkit input", "  @gift-user  ");
    await click(".cstore-gift-formkit .btn-primary");

    assert.deepEqual(this.giftCalls, [[42, "gift-user"]]);
  });
});
