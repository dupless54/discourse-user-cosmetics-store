import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreHealthAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-health-admin";
import { i18n } from "discourse-i18n";

module("Component | CosmeticsStoreHealthAdmin", function (hooks) {
  setupRenderingTest(hooks);

  test("renders localized native diagnostics and server-derived values", async function (assert) {
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
    assert
      .dom(".cstore-health__overall")
      .hasText(i18n("discourse_cosmetics_store.admin.health.overall.warning"));
    assert.dom("table.d-table.cstore-health__table").exists();
    assert.dom("tbody.d-table__body tr.d-table__row").exists({ count: 4 });
    assert.dom(".d-table__mobile-label").exists();
    assert
      .dom(".cstore-health")
      .includesText(
        i18n("discourse_cosmetics_store.admin.health.checks.integration.label")
      );
    assert
      .dom(".cstore-health")
      .includesText(
        i18n(
          "discourse_cosmetics_store.admin.health.checks.integration_contract.label"
        )
      );
    assert
      .dom(".cstore-health")
      .includesText(
        i18n("discourse_cosmetics_store.admin.health.values.manifest", {
          version: 1,
        })
      );
    assert
      .dom(".cstore-health")
      .includesText(
        i18n(
          "discourse_cosmetics_store.admin.health.checks.empty_products.label"
        )
      );
    assert
      .dom(".cstore-health")
      .includesText(
        i18n("discourse_cosmetics_store.admin.health.values.providers_ready", {
          count: 1,
          total: 6,
        })
      );
  });
});
