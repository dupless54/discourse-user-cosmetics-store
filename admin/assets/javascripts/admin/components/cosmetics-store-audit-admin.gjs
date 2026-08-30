import Component from "@glimmer/component";
import DFilterControls from "discourse/ui-kit/d-filter-controls";
import { i18n } from "discourse-i18n";

const ACTION_KEYS = {
  product_created: "product_created",
  product_updated: "product_updated",
  product_deleted: "product_deleted",
  mission_created: "mission_created",
  mission_updated: "mission_updated",
  mission_deleted: "mission_deleted",
  mission_disabled: "mission_disabled",
  wallet_adjusted: "wallet_adjusted",
  orb_package_created: "orb_package_created",
  orb_package_updated: "orb_package_updated",
  orb_package_deleted: "orb_package_deleted",
  orb_package_disabled: "orb_package_disabled",
  refund_recorded: "refund_recorded",
};

const DETAIL_KEYS = {
  entity_id: "entity_id",
  entity_name: "entity_name",
  entity_type: "entity_type",
  changed_fields: "changed_fields",
  target_user_id: "target_user_id",
  target_username: "target_username",
  amount: "amount",
  balance_after: "balance_after",
  debt_after: "debt_after",
  orb_amount: "orb_amount",
  price_minor: "price_minor",
  currency: "currency",
  payment_id: "payment_id",
  refund_id: "refund_id",
  refund_amount_minor: "refund_amount_minor",
  refunded_orb_amount: "refunded_orb_amount",
};

const AUDIT_LOCALE = "discourse_cosmetics_store.admin.audit";

export default class CosmeticsStoreAuditAdmin extends Component {
  searchableProps = [
    "actor.username",
    "actionLabel",
    "subject",
    "searchText",
  ];

  get entries() {
    return this.args.entries ?? [];
  }

  actionLabel(actionName) {
    const key = ACTION_KEYS[actionName];
    return key ? i18n(`${AUDIT_LOCALE}.actions.${key}`) : actionName;
  }

  detailLabel(key) {
    const localeKey = DETAIL_KEYS[key];
    return localeKey ? i18n(`${AUDIT_LOCALE}.details.${localeKey}`) : key;
  }

  get rows() {
    return this.entries.map((entry) => {
      const actionLabel = this.actionLabel(entry.action);
      const detailRows = Object.entries(entry.details ?? {}).map(
        ([key, value]) => ({
          key,
          label: this.detailLabel(key),
          value,
        })
      );

      return {
        ...entry,
        actionLabel,
        detailRows,
        searchText: Object.values(entry.details ?? {}).filter(Boolean).join(" "),
      };
    });
  }

  get actionOptions() {
    const actions = [...new Set(this.entries.map((entry) => entry.action))].sort();
    return [
      {
        value: "all",
        label: i18n(`${AUDIT_LOCALE}.all_actions`),
      },
      ...actions.map((actionName) => ({
        value: actionName,
        label: this.actionLabel(actionName),
        filterFn: (row) => row.action === actionName,
      })),
    ];
  }

  <template>
    <section class="cstore-audit" aria-labelledby="cstore-audit-title">
      <div class="cstore-audit__heading">
        <div>
          <p>{{i18n "discourse_cosmetics_store.admin.audit.eyebrow"}}</p>
          <h2 id="cstore-audit-title">
            {{i18n "discourse_cosmetics_store.admin.audit.title"}}
          </h2>
          <span>
            {{i18n
              "discourse_cosmetics_store.admin.audit.description"
              count=this.entries.length
            }}
          </span>
        </div>
        <small>{{i18n "discourse_cosmetics_store.admin.audit.read_only"}}</small>
      </div>

      <DFilterControls
        @array={{this.rows}}
        @searchableProps={{this.searchableProps}}
        @dropdownOptions={{this.actionOptions}}
        @inputPlaceholder={{i18n
          "discourse_cosmetics_store.admin.audit.search_placeholder"
        }}
        @noResultsMessage={{i18n
          "discourse_cosmetics_store.admin.audit.empty"
        }}
      >
        <:content as |rows|>
          {{#if rows.length}}
            <div class="cstore-admin-table-wrap">
              <table class="d-table cstore-admin-table cstore-audit__table">
                <thead class="d-table__header">
                  <tr class="d-table__row">
                    <th>{{i18n "discourse_cosmetics_store.admin.audit.columns.action"}}</th>
                    <th>{{i18n "discourse_cosmetics_store.admin.audit.columns.actor"}}</th>
                    <th>{{i18n "discourse_cosmetics_store.admin.audit.columns.subject"}}</th>
                    <th>{{i18n "discourse_cosmetics_store.admin.audit.columns.details"}}</th>
                    <th>{{i18n "discourse_cosmetics_store.admin.audit.columns.time"}}</th>
                  </tr>
                </thead>
                <tbody class="d-table__body">
                  {{#each rows as |row|}}
                    <tr class="d-table__row">
                      <td class="d-table__cell --overview">
                        <strong>{{row.actionLabel}}</strong>
                      </td>
                      <td class="d-table__cell --detail">
                        <div class="d-table__mobile-label">
                          {{i18n "discourse_cosmetics_store.admin.audit.columns.actor"}}
                        </div>
                        @{{row.actor.username}}
                      </td>
                      <td class="d-table__cell --detail">
                        <div class="d-table__mobile-label">
                          {{i18n "discourse_cosmetics_store.admin.audit.columns.subject"}}
                        </div>
                        {{row.subject}}
                      </td>
                      <td class="d-table__cell --detail">
                        <div class="d-table__mobile-label">
                          {{i18n "discourse_cosmetics_store.admin.audit.columns.details"}}
                        </div>
                        {{#if row.detailRows.length}}
                          <div class="cstore-audit-table__details">
                            {{#each row.detailRows as |detail|}}
                              <div>
                                <strong>{{detail.label}}:</strong>
                                {{detail.value}}
                              </div>
                            {{/each}}
                          </div>
                        {{else}}
                          —
                        {{/if}}
                      </td>
                      <td class="d-table__cell --detail">
                        <div class="d-table__mobile-label">
                          {{i18n "discourse_cosmetics_store.admin.audit.columns.time"}}
                        </div>
                        <time datetime={{row.created_at}}>{{row.created_at}}</time>
                      </td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
            </div>
          {{/if}}
        </:content>
      </DFilterControls>
    </section>
  </template>
}
