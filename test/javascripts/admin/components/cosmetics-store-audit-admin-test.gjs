import { click, fillIn, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreAuditAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-audit-admin";

module("Component | CosmeticsStoreAuditAdmin", function (hooks) {
  setupRenderingTest(hooks);

  test("renders safe audit rows and filters them by actor or action", async function (assert) {
    this.entries = [
      {
        id: 2,
        action: "wallet_adjusted",
        subject: "user:42",
        actor: { id: 1, username: "alice" },
        details: {
          target_username: "member",
          amount: "30",
          balance_after: "80",
        },
        created_at: "2026-08-29T00:10:00Z",
      },
      {
        id: 1,
        action: "product_created",
        subject: "product:8",
        actor: { id: 2, username: "bob" },
        details: {
          entity_name: "Neon Frame",
          changed_fields: "name|price",
        },
        created_at: "2026-08-29T00:00:00Z",
      },
    ];

    await render(
      <template><CosmeticsStoreAuditAdmin @entries={{this.entries}} /></template>
    );

    assert.dom(".cstore-audit__entry").exists({ count: 2 });
    assert.dom(".cstore-audit").includesText("Cüzdan ayarlandı");
    assert.dom(".cstore-audit").includesText("Ürün oluşturuldu");
    assert.dom(".cstore-audit").doesNotIncludeText("secret");

    await fillIn('.cstore-audit__filters input[type="search"]', "alice");

    assert.dom(".cstore-audit__entry").exists({ count: 1 });
    assert.dom(".cstore-audit").includesText("@alice");
    assert.dom(".cstore-audit").doesNotIncludeText("@bob");

    await click(".cstore-audit__filters button");

    assert.dom(".cstore-audit__entry").exists({ count: 2 });
  });
});
