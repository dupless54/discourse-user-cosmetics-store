import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStorePaymentRefundModal from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-payment-refund-modal";

module("Component | CosmeticsStorePaymentRefundModal", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.model = {
      payment: {
        token: "payment-1",
        username: "alice",
        package_name: "Starter Orbs",
        provider: "shopier",
        remaining_amount: "49.90",
        currency: "TRY",
        provider_payment_id: "ORDER-1",
      },
      onCompleted() {},
    };
    this.closeModal = () => {};
  });

  test("renders the native FormKit refund confirmation", async function (assert) {
    await render(
      <template>
        <CosmeticsStorePaymentRefundModal
          @model={{this.model}}
          @closeModal={{this.closeModal}}
          @inline={{true}}
        />
      </template>
    );

    assert.dom(".d-modal.cstore-refund-modal").exists();
    assert.dom(".cstore-refund-form__warning").exists();
    assert.dom('input[name="amount"]').hasValue("49.90");
    assert.dom('input[name="refund_reference"]').exists();
    assert.dom('input[name="reason"]').exists();
    assert.dom('input[name="confirmed"]').exists();
    assert.dom(".d-modal__footer .btn-danger").exists();
    assert.dom("form.cstore-refund-form").doesNotExist();
  });
});
