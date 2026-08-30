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
import CosmeticsStorePaymentRefundModal from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-payment-refund-modal";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";
const EDIT_ROUTE = "adminPlugins.show.cosmetics-store-payments.edit";
const NEW_ROUTE = "adminPlugins.show.cosmetics-store-payments.new";

export default class CosmeticsStorePaymentsAdmin extends Component {
  @service dialog;
  @service modal;

  @tracked packages = this.args.model?.orb_packages ?? [];
  @tracked paymentRows = this.args.model?.payments ?? [];
  @tracked status = null;

  get providers() {
    return this.args.model?.payment_providers ?? [];
  }

  get payments() {
    return this.paymentRows;
  }

  @action
  removePackage(packageRow) {
    const messageKey = packageRow.payment_count
      ? "discourse_cosmetics_store.admin.orb_package.disable_confirm"
      : "discourse_cosmetics_store.admin.orb_package.delete_confirm";

    return this.dialog.confirm({
      message: i18n(messageKey, { name: packageRow.name }),
      didConfirm: async () => {
        try {
          const response = await ajax(
            `${ADMIN_API_BASE}/orb-packages/${packageRow.id}.json`,
            { type: "DELETE" }
          );

          if (response?.disabled_instead_of_deleted) {
            const packages = this.packages.map((row) =>
              row.id === packageRow.id ? response : row
            );
            this.packages = packages;
            this.args.model.orb_packages = packages;
            this.status = i18n(
              "discourse_cosmetics_store.admin.orb_package.disabled_with_history"
            );
          } else {
            const packages = this.packages.filter(
              (row) => row.id !== packageRow.id
            );
            this.packages = packages;
            this.args.model.orb_packages = packages;
            this.status = i18n(
              "discourse_cosmetics_store.admin.orb_package.deleted"
            );
          }
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  @action
  beginRefund(payment) {
    return this.modal.show(CosmeticsStorePaymentRefundModal, {
      model: {
        payment,
        onCompleted: this.refundCompleted,
      },
    });
  }

  @action
  refundCompleted(response) {
    const payments = this.paymentRows.map((row) =>
      row.token === response.token ? response : row
    );
    this.paymentRows = payments;
    this.args.model.payments = payments;
    this.status = response.message;
  }

  <template>
    <section class="cstore-admin cstore-admin-payments">
      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      <section class="cstore-admin-payments__providers">
        <h3>{{i18n "discourse_cosmetics_store.admin.payment.providers_title"}}</h3>
        <p>{{i18n "discourse_cosmetics_store.admin.payment.providers_help"}}</p>

        <div class="cstore-provider-status">
          {{#each this.providers as |provider|}}
            <article class={{if provider.enabled "is-ready" "is-off"}}>
              <header>
                <strong>{{provider.label}}</strong>
                <span>
                  {{if
                    provider.enabled
                    (i18n "discourse_cosmetics_store.admin.payment.provider_ready")
                    (i18n "discourse_cosmetics_store.admin.payment.provider_unavailable")
                  }}
                </span>
              </header>

              {{#if provider.webhook_url}}
                <label>
                  {{i18n "discourse_cosmetics_store.admin.payment.webhook_url"}}
                  <input readonly value={{provider.webhook_url}} />
                </label>
              {{/if}}
              {{#if provider.osb_callback_url}}
                <label>
                  {{i18n "discourse_cosmetics_store.admin.payment.osb_callback_url"}}
                  <input readonly value={{provider.osb_callback_url}} />
                </label>
              {{/if}}
              {{#if provider.callback_url}}
                <label>
                  {{i18n "discourse_cosmetics_store.admin.payment.callback_url"}}
                  <input readonly value={{provider.callback_url}} />
                </label>
              {{/if}}

              {{#if provider.automatic_refunds}}
                <p class="cstore-provider-status__refund is-automatic">
                  {{i18n "discourse_cosmetics_store.admin.payment.refunds_automatic"}}
                </p>
              {{else if provider.manual_refunds}}
                <p class="cstore-provider-status__refund">
                  {{i18n "discourse_cosmetics_store.admin.payment.refunds_manual"}}
                </p>
              {{/if}}
            </article>
          {{/each}}
        </div>
      </section>

      <section class="cstore-admin-payments__packages">
        <h3>{{i18n "discourse_cosmetics_store.admin.payment.packages_title"}}</h3>
        <p>{{i18n "discourse_cosmetics_store.admin.payment.packages_help"}}</p>

        {{#if this.packages.length}}
          <div class="cstore-admin-table-wrap">
            <table class="d-table cstore-admin-table cstore-admin-orb-packages-table">
              <thead class="d-table__header">
                <tr>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.package"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.orbs"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.price"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.providers"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.status"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.orb_package.columns.actions"}}</th>
                </tr>
              </thead>
              <tbody class="d-table__body">
                {{#each this.packages as |packageRow|}}
                  <tr class="d-table__row">
                    <td class="d-table__cell --overview">
                      <strong>{{packageRow.name}}</strong>
                      <small>
                        {{i18n
                          "discourse_cosmetics_store.admin.orb_package.payment_count"
                          count=packageRow.payment_count
                        }}
                      </small>
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.orb_package.columns.orbs"}}</div>
                      {{packageRow.orb_amount}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.orb_package.columns.price"}}</div>
                      {{packageRow.price}} {{packageRow.currency}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.orb_package.columns.providers"}}</div>
                      {{packageRow.providers.length}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.orb_package.columns.status"}}</div>
                      <span class={{if packageRow.enabled "is-on" "is-off"}}>
                        {{if
                          packageRow.enabled
                          (i18n "discourse_cosmetics_store.admin.orb_package.enabled")
                          (i18n "discourse_cosmetics_store.admin.orb_package.disabled")
                        }}
                      </span>
                    </td>
                    <td class="d-table__cell --controls">
                      <div class="d-table__cell-actions">
                        <DButton
                          class="btn-default btn-small"
                          @route={{EDIT_ROUTE}}
                          @routeModels={{packageRow.id}}
                          @label="discourse_cosmetics_store.admin.orb_package.edit_action"
                        />
                        <DButton
                          class="btn-transparent --danger btn-small"
                          @action={{fn this.removePackage packageRow}}
                          @icon={{if packageRow.payment_count "ban" "trash-can"}}
                          @label={{if
                            packageRow.payment_count
                            "discourse_cosmetics_store.admin.orb_package.disable"
                            "discourse_cosmetics_store.admin.orb_package.delete"
                          }}
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
            @emptyLabel="discourse_cosmetics_store.admin.orb_package.empty"
            @ctaLabel="discourse_cosmetics_store.admin.orb_package.add"
            @ctaRoute={{NEW_ROUTE}}
          />
        {{/if}}
      </section>

      <section class="cstore-admin-payments__history">
        <h3>{{i18n "discourse_cosmetics_store.admin.payment.history_title"}}</h3>
        <p>{{i18n "discourse_cosmetics_store.admin.payment.history_help"}}</p>

        {{#if this.payments.length}}
          <div class="cstore-admin-table-wrap">
            <table class="d-table cstore-admin-table cstore-admin-payments-table">
              <thead class="d-table__header">
                <tr>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.user"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.package"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.provider"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.amount"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.orbs"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.status"}}</th>
                  <th>{{i18n "discourse_cosmetics_store.admin.payment.columns.actions"}}</th>
                </tr>
              </thead>
              <tbody class="d-table__body">
                {{#each this.payments as |payment|}}
                  <tr class="d-table__row">
                    <td class="d-table__cell --overview">@{{payment.username}}</td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.payment.columns.package"}}</div>
                      {{payment.package_name}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.payment.columns.provider"}}</div>
                      {{payment.provider}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.payment.columns.amount"}}</div>
                      {{payment.amount}} {{payment.currency}}
                      {{#if payment.refunded_amount_minor}}
                        <small>
                          {{i18n
                            "discourse_cosmetics_store.admin.payment.refunded_amount"
                            amount=payment.refunded_amount
                            currency=payment.currency
                          }}
                        </small>
                      {{/if}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.payment.columns.orbs"}}</div>
                      {{payment.orb_amount}}
                      {{#if payment.refunded_orb_amount}}
                        <small>
                          {{i18n
                            "discourse_cosmetics_store.admin.payment.refunded_orbs"
                            count=payment.refunded_orb_amount
                          }}
                        </small>
                      {{/if}}
                    </td>
                    <td class="d-table__cell --detail">
                      <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.payment.columns.status"}}</div>
                      <span class="is-payment-{{payment.status}}">{{payment.status}}</span>
                      {{#if payment.failure_message}}
                        <small>{{payment.failure_message}}</small>
                      {{/if}}
                      {{#each payment.refunds as |refund|}}
                        <small>
                          {{refund.source}} · {{refund.provider_refund_id}} · {{refund.status}}
                        </small>
                      {{/each}}
                    </td>
                    <td class="d-table__cell --controls">
                      {{#if payment.refundable}}
                        <DButton
                          class="btn-default btn-small"
                          @action={{fn this.beginRefund payment}}
                          @label="discourse_cosmetics_store.admin.refund.action"
                        />
                      {{else}}
                        —
                      {{/if}}
                    </td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        {{else}}
          <AdminConfigAreaEmptyList
            @emptyLabel="discourse_cosmetics_store.admin.payment.empty"
          />
        {{/if}}
      </section>
    </section>
  </template>
}
