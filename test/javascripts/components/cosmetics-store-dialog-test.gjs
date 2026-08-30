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

    const modal = document.querySelector(".d-modal.cstore-dialog");

    assert.ok(modal, "renders through the Discourse DModal portal");
    assert
      .dom(modal.querySelector(".d-modal__title-text"))
      .hasText("Ölülerin Efendisi (Mavi)");
    assert.notOk(
      document.querySelector(".cstore-dialog__backdrop"),
      "does not render the removed custom backdrop"
    );
    assert.notOk(
      document.querySelector(".cstore-dialog__close"),
      "does not render the removed custom close button"
    );
    assert.dom(modal.querySelector(".cstore-dialog__purchase")).exists();

    await click(modal.querySelector(".cstore-buy"));

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

    const modal = document.querySelector(".d-modal.cstore-dialog");

    assert.ok(modal, "renders through the Discourse DModal portal");
    await click(modal.querySelector(".cstore-gift-toggle"));

    const giftForm = modal.querySelector(".cstore-gift-formkit");
    const recipientInput = giftForm?.querySelector("input");

    assert.dom(giftForm).exists();
    assert.dom(recipientInput).exists();

    await fillIn(recipientInput, "  @gift-user  ");
    await click(giftForm.querySelector(".btn-primary"));

    assert.deepEqual(this.giftCalls, [[42, "gift-user"]]);
  });
});
