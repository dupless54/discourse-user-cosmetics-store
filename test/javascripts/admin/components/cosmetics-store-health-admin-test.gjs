import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreHealthAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-health-admin";

module("Component | CosmeticsStoreHealthAdmin", function (hooks) {
  setupRenderingTest(hooks);

  test("renders overall state and individual diagnostic values", async function (assert) {
    this.health = {
      status: "warning",
      checked_at: "2026-08-29T00:00:00Z",
      checks: [
        { id: "integration", status: "ok", value: 1 },
        {
          id: "integration_contract",
          status: "ok",
          value: 1,
          mode: "manifest",
          supported_versions: [1],
        },
        { id: "empty_products", status: "warning", value: 2 },
        {
          id: "payment_providers",
          status: "ok",
          value: 1,
          total: 6,
          payments_enabled: true,
        },
      ],
    };

    await render(
      <template><CosmeticsStoreHealthAdmin @health={{this.health}} /></template>
    );

    assert.dom(".cstore-health").hasClass("cstore-health--warning");
    assert.dom(".cstore-health__overall").hasText("Kontrol gerekli");
    assert.dom("table.d-table.cstore-health__table").exists();
    assert.dom("tbody.d-table__body tr.d-table__row").exists({ count: 4 });
    assert.dom(".d-table__mobile-label").exists();
    assert.dom(".cstore-health").includesText("Resmî Integration API");
    assert.dom(".cstore-health").includesText("Integration sözleşme sürümü");
    assert.dom(".cstore-health").includesText("v1 manifest");
    assert.dom(".cstore-health").includesText("İçeriği boş etkin ürünler");
    assert.dom(".cstore-health").includesText("1 / 6 yapılandırılmış");
  });
});
