import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreOrbPackageForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-orb-package-form";

module("Component | CosmeticsStoreOrbPackageForm", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.catalog = {
      orb_packages: [],
      payment_providers: [
        { id: "shopier", label: "Shopier", enabled: true },
        { id: "stripe", label: "Stripe", enabled: false },
      ],
    };
  });

  test("renders the native FormKit Orb package editor", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreOrbPackageForm @catalog={{this.catalog}} @package={{null}} />
      </template>
    );

    assert.dom('input[name="name"]').exists();
    assert.dom('input[name="orb_amount"]').exists();
    assert.dom('input[name="price"]').exists();
    assert.dom('select[name="currency"]').exists();
    assert.dom('textarea[name="description"]').exists();
    assert.dom(".cstore-admin-provider-flags").exists();
    assert.dom('.cstore-admin-provider-flags input[type="checkbox"]').exists({ count: 2 });
    assert.dom('.cstore-admin-provider-flags input[type="checkbox"]:disabled').exists({ count: 1 });
    assert.dom(".cstore-admin-form").doesNotExist();
  });
});
