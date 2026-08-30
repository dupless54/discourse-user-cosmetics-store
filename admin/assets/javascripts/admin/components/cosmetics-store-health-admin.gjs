import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

const HEALTH_LOCALE = "discourse_cosmetics_store.admin.health";

const CHECK_KEYS = {
  store_enabled: "store_enabled",
  base_plugin: "base_plugin",
  integration: "integration",
  integration_contract: "integration_contract",
  preview_contract: "preview_contract",
  loadout_contract: "loadout_contract",
  empty_products: "empty_products",
  disabled_cosmetic_items: "disabled_cosmetic_items",
  invalid_availability: "invalid_availability",
  payment_providers: "payment_providers",
};

export default class CosmeticsStoreHealthAdmin extends Component {
  get health() {
    return this.args.health ?? { status: "critical", checks: [] };
  }

  get statusLabel() {
    const key = ["healthy", "warning", "critical"].includes(this.health.status)
      ? this.health.status
      : "unknown";
    return i18n(`${HEALTH_LOCALE}.overall.${key}`);
  }

  checkLabel(check) {
    const key = CHECK_KEYS[check.id];
    return key ? i18n(`${HEALTH_LOCALE}.checks.${key}.label`) : check.id;
  }

  checkDescription(check) {
    const key = CHECK_KEYS[check.id];
    return key ? i18n(`${HEALTH_LOCALE}.checks.${key}.description`) : "";
  }

  checkStatusLabel(status) {
    const key = ["ok", "warning", "critical"].includes(status)
      ? status
      : "unknown";
    return i18n(`${HEALTH_LOCALE}.check_status.${key}`);
  }

  get rows() {
    return (this.health.checks ?? []).map((check) => ({
      ...check,
      label: this.checkLabel(check),
      description: this.checkDescription(check),
      valueLabel: this.valueLabel(check),
      statusLabel: this.checkStatusLabel(check.status),
    }));
  }

  valueLabel(check) {
    if (check.id === "payment_providers") {
      return check.payments_enabled
        ? i18n(`${HEALTH_LOCALE}.values.providers_ready`, {
            count: check.value,
            total: check.total,
          })
        : i18n(`${HEALTH_LOCALE}.values.providers_disabled`, {
            count: check.value,
            total: check.total,
          });
    }

    if (check.id === "integration_contract") {
      if (check.mode === "manifest") {
        return i18n(`${HEALTH_LOCALE}.values.manifest`, {
          version: check.value,
        });
      }
      if (check.mode === "legacy") {
        return i18n(`${HEALTH_LOCALE}.values.legacy`);
      }
      if (check.mode === "missing") {
        return i18n(`${HEALTH_LOCALE}.values.base_missing`);
      }

      return check.value
        ? i18n(`${HEALTH_LOCALE}.values.unsupported`, {
            version: check.value,
          })
        : i18n(`${HEALTH_LOCALE}.values.invalid_manifest`);
    }

    if (
      [
        "store_enabled",
        "base_plugin",
        "integration",
        "preview_contract",
        "loadout_contract",
      ].includes(check.id)
    ) {
      return check.value
        ? i18n(`${HEALTH_LOCALE}.values.ready`)
        : i18n(`${HEALTH_LOCALE}.values.not_ready`);
    }

    return String(check.value ?? 0);
  }

  <template>
    <section
      class="cstore-health cstore-health--{{this.health.status}}"
      aria-labelledby="cstore-health-title"
    >
      <div class="cstore-health__heading">
        <div>
          <p>{{i18n "discourse_cosmetics_store.admin.health.eyebrow"}}</p>
          <h2 id="cstore-health-title">
            {{i18n "discourse_cosmetics_store.admin.health.title"}}
          </h2>
          <span>{{i18n "discourse_cosmetics_store.admin.health.description"}}</span>
        </div>
        <strong class="cstore-health__overall">{{this.statusLabel}}</strong>
      </div>

      <div class="cstore-admin-table-wrap">
        <table class="d-table cstore-admin-table cstore-health__table">
          <thead class="d-table__header">
            <tr class="d-table__row">
              <th>{{i18n "discourse_cosmetics_store.admin.health.columns.check"}}</th>
              <th>{{i18n "discourse_cosmetics_store.admin.health.columns.status"}}</th>
              <th>{{i18n "discourse_cosmetics_store.admin.health.columns.value"}}</th>
              <th>{{i18n "discourse_cosmetics_store.admin.health.columns.description"}}</th>
            </tr>
          </thead>
          <tbody class="d-table__body">
            {{#each this.rows as |row|}}
              <tr class="d-table__row">
                <td class="d-table__cell --overview">
                  <strong>{{row.label}}</strong>
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">
                    {{i18n "discourse_cosmetics_store.admin.health.columns.status"}}
                  </div>
                  <span>{{row.statusLabel}}</span>
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">
                    {{i18n "discourse_cosmetics_store.admin.health.columns.value"}}
                  </div>
                  <b>{{row.valueLabel}}</b>
                </td>
                <td class="d-table__cell --detail">
                  <div class="d-table__mobile-label">
                    {{i18n "discourse_cosmetics_store.admin.health.columns.description"}}
                  </div>
                  {{row.description}}
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>

      {{#if this.health.checked_at}}
        <small class="cstore-health__checked-at">
          {{i18n
            "discourse_cosmetics_store.admin.health.checked_at"
            timestamp=this.health.checked_at
          }}
        </small>
      {{/if}}
    </section>
  </template>
}
