import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaEmptyList from "discourse/admin/components/admin-config-area-empty-list";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const EDIT_ROUTE = "adminPlugins.show.cosmetics-store-missions.edit";
const NEW_ROUTE = "adminPlugins.show.cosmetics-store-missions.new";

export default class CosmeticsStoreMissionsAdmin extends Component {
  @service dialog;

  @tracked missions = this.args.model?.missions ?? [];
  @tracked status = null;

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
  }

  @action
  deleteMission(mission) {
    const message = mission.claim_count
      ? i18n("discourse_cosmetics_store.admin.mission.disable_confirm", {
          name: mission.name,
        })
      : i18n("discourse_cosmetics_store.admin.mission.delete_confirm", {
          name: mission.name,
        });

    return this.dialog.confirm({
      message,
      didConfirm: async () => {
        try {
          await ajax(`${ADMIN_API_BASE}/missions/${mission.id}.json`, {
            type: "DELETE",
          });

          if (mission.claim_count > 0) {
            const missions = this.missions.map((row) =>
              row.id === mission.id ? { ...row, enabled: false } : row
            );
            this.missions = missions;
            this.args.model.missions = missions;
            this.status = i18n(
              "discourse_cosmetics_store.admin.mission.disabled_with_history"
            );
          } else {
            const missions = this.missions.filter(
              (row) => row.id !== mission.id
            );
            this.missions = missions;
            this.args.model.missions = missions;
            this.status = i18n("discourse_cosmetics_store.admin.mission.deleted");
          }
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  <template>
    <section class="cstore-admin cstore-admin-missions-section">
      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      {{#if this.missions.length}}
        <div class="cstore-admin-table-wrap">
          <table class="d-table cstore-admin-table cstore-admin-missions-table">
            <thead class="d-table__header">
              <tr>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.mission"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.metric"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.target"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.reward"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.claims"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.status"}}</th>
                <th>{{i18n "discourse_cosmetics_store.admin.mission.columns.actions"}}</th>
              </tr>
            </thead>
            <tbody class="d-table__body">
              {{#each this.missions as |mission|}}
                <tr class="d-table__row">
                  <td class="d-table__cell --overview">
                    <span class="cstore-admin-missions-table__icon" aria-hidden="true">{{mission.icon}}</span>
                    <span>
                      <strong>{{mission.name}}</strong>
                      {{#if mission.description}}<small>{{mission.description}}</small>{{/if}}
                    </span>
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.mission.columns.metric"}}</div>
                    {{mission.metric}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.mission.columns.target"}}</div>
                    {{mission.target}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.mission.columns.reward"}}</div>
                    +{{mission.reward}} {{this.settings.currency_symbol}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.mission.columns.claims"}}</div>
                    {{mission.claim_count}}
                  </td>
                  <td class="d-table__cell --detail">
                    <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.mission.columns.status"}}</div>
                    <span class={{if mission.enabled "is-on" "is-off"}}>
                      {{if mission.enabled (i18n "discourse_cosmetics_store.admin.mission.enabled") (i18n "discourse_cosmetics_store.admin.mission.disabled")}}
                    </span>
                  </td>
                  <td class="d-table__cell --controls">
                    <div class="d-table__cell-actions">
                      <DButton
                        class="btn-default btn-small"
                        @route={{EDIT_ROUTE}}
                        @routeModels={{mission.id}}
                        @label="discourse_cosmetics_store.admin.mission.edit_action"
                      />
                      <DButton
                        class="btn-transparent --danger btn-small"
                        @action={{fn this.deleteMission mission}}
                        @icon={{if mission.claim_count "ban" "trash-can"}}
                        @label={{if mission.claim_count "discourse_cosmetics_store.admin.mission.disable" "discourse_cosmetics_store.admin.mission.delete"}}
                      />
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <AdminConfigAreaEmptyList
          @emptyLabel="discourse_cosmetics_store.admin.mission.empty"
          @ctaLabel="discourse_cosmetics_store.admin.mission.add"
          @ctaRoute={{NEW_ROUTE}}
        />
      {{/if}}
    </section>
  </template>
}
