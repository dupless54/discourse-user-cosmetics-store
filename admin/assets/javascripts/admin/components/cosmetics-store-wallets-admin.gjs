import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import AdminConfigAreaEmptyList from "discourse/admin/components/admin-config-area-empty-list";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

export default class CosmeticsStoreWalletsAdmin extends Component {
  @service dialog;

  @tracked walletResult = null;
  @tracked status = null;
  @tracked searching = false;
  @tracked adjusting = false;

  searchData = { username: "" };
  adjustmentData = { amount: 0, reason: "" };
  adjustmentFormApi = null;

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
  }

  @action
  registerAdjustmentForm(api) {
    this.adjustmentFormApi = api;
  }

  @action
  async findWallet(data) {
    const username = String(data.username || "").trim();
    if (!username || this.searching) {
      return;
    }

    this.searching = true;
    this.status = null;

    try {
      this.walletResult = await ajax(
        `${ADMIN_API_BASE}/wallet.json?username=${encodeURIComponent(username)}`
      );
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.searching = false;
    }
  }

  @action
  adjustWallet(data) {
    if (!this.walletResult || this.adjusting) {
      return;
    }

    const amount = Number.parseInt(String(data.amount || "0"), 10);
    const reason = String(data.reason || "").trim();
    if (!Number.isInteger(amount) || amount === 0 || !reason) {
      return;
    }

    return this.dialog.confirm({
      message: i18n("discourse_cosmetics_store.admin.wallet.confirm_adjustment", {
        amount,
        symbol: this.settings.currency_symbol,
        username: this.walletResult.user.username,
      }),
      didConfirm: () => this.persistAdjustment(amount, reason),
    });
  }

  async persistAdjustment(amount, reason) {
    this.adjusting = true;

    try {
      const result = await ajax(`${ADMIN_API_BASE}/wallet/adjust.json`, {
        type: "POST",
        data: {
          username: this.walletResult.user.username,
          amount,
          reason,
        },
      });

      this.walletResult = result;
      this.status =
        result.message ||
        i18n("discourse_cosmetics_store.admin.wallet.adjusted");
      await this.adjustmentFormApi?.setProperties({ amount: 0, reason: "" });
      this.adjustmentFormApi?.commit();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.adjusting = false;
    }
  }

  <template>
    <section class="cstore-admin cstore-admin-wallets">
      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      <div class="admin-config-area">
        <div class="admin-config-area__primary-content">
          <AdminConfigAreaCard
            @heading="discourse_cosmetics_store.admin.wallet.lookup_title"
          >
            <:content>
              <p>{{i18n "discourse_cosmetics_store.admin.wallet.lookup_help"}}</p>
              <Form @onSubmit={{this.findWallet}} @data={{this.searchData}} as |form|>
                <form.Field
                  @name="username"
                  @title={{i18n "discourse_cosmetics_store.admin.wallet.username"}}
                  @validation="required"
                  @format="large"
                  @type="input"
                  as |field|
                >
                  <field.Control
                    autocomplete="off"
                    placeholder={{i18n "discourse_cosmetics_store.admin.wallet.username_placeholder"}}
                  />
                </form.Field>
                <form.Submit
                  @label="discourse_cosmetics_store.admin.wallet.lookup_action"
                  @disabled={{this.searching}}
                />
              </Form>
            </:content>
          </AdminConfigAreaCard>
        </div>
      </div>

      {{#if this.walletResult}}
        <div class="cstore-wallet-card">
          <header>
            <img src={{this.walletResult.user.avatar_url}} alt="" />
            <div>
              <strong>{{this.walletResult.user.name}}</strong>
              <span>@{{this.walletResult.user.username}}</span>
            </div>
            <b>{{this.settings.currency_symbol}} {{this.walletResult.wallet.balance}}</b>
          </header>

          {{#if this.walletResult.wallet.debt}}
            <div class="cstore-wallet-card__debt">
              <strong>
                {{this.walletResult.wallet.debt}} {{this.settings.currency_symbol}}
                {{i18n "discourse_cosmetics_store.admin.wallet.refund_debt"}}
              </strong>
              <span>{{i18n "discourse_cosmetics_store.admin.wallet.debt_help"}}</span>
            </div>
          {{/if}}

          <div class="cstore-wallet-card__stats">
            <span>
              <strong>{{this.walletResult.wallet.lifetime_earned}}</strong>
              <small>{{i18n "discourse_cosmetics_store.admin.wallet.lifetime_earned"}}</small>
            </span>
            <span>
              <strong>{{this.walletResult.wallet.lifetime_spent}}</strong>
              <small>{{i18n "discourse_cosmetics_store.admin.wallet.lifetime_spent"}}</small>
            </span>
            {{#if this.walletResult.wallet.debt}}
              <span>
                <strong>{{this.walletResult.wallet.debt}}</strong>
                <small>{{i18n "discourse_cosmetics_store.admin.wallet.refund_debt"}}</small>
              </span>
            {{/if}}
          </div>

          <div class="admin-config-area">
            <div class="admin-config-area__primary-content">
              <AdminConfigAreaCard
                @heading="discourse_cosmetics_store.admin.wallet.adjust_title"
              >
                <:content>
                  <p>{{i18n "discourse_cosmetics_store.admin.wallet.adjust_help"}}</p>
                  <Form
                    @commitOnSubmit={{false}}
                    @onSubmit={{this.adjustWallet}}
                    @onRegisterApi={{this.registerAdjustmentForm}}
                    @data={{this.adjustmentData}}
                    as |form|
                  >
                    <form.Field
                      @name="amount"
                      @title={{i18n "discourse_cosmetics_store.admin.wallet.amount"}}
                      @validation="required"
                      @type="input-number"
                      as |field|
                    >
                      <field.Control step="1" />
                    </form.Field>
                    <form.Field
                      @name="reason"
                      @title={{i18n "discourse_cosmetics_store.admin.wallet.reason"}}
                      @validation="required"
                      @format="large"
                      @type="input"
                      as |field|
                    >
                      <field.Control
                        maxlength="500"
                        placeholder={{i18n "discourse_cosmetics_store.admin.wallet.reason_placeholder"}}
                      />
                    </form.Field>
                    <form.Submit
                      @label="discourse_cosmetics_store.admin.wallet.adjust_action"
                      @disabled={{this.adjusting}}
                    />
                  </Form>
                </:content>
              </AdminConfigAreaCard>
            </div>
          </div>

          <section class="cstore-wallet-ledger">
            <h3>{{i18n "discourse_cosmetics_store.admin.wallet.recent_ledger"}}</h3>
            {{#if this.walletResult.wallet.ledger.length}}
              <div class="cstore-admin-table-wrap">
                <table class="d-table cstore-admin-table cstore-wallet-ledger__table">
                  <thead class="d-table__header">
                    <tr>
                      <th>{{i18n "discourse_cosmetics_store.admin.wallet.columns.amount"}}</th>
                      <th>{{i18n "discourse_cosmetics_store.admin.wallet.columns.reason"}}</th>
                      <th>{{i18n "discourse_cosmetics_store.admin.wallet.columns.type"}}</th>
                      <th>{{i18n "discourse_cosmetics_store.admin.wallet.columns.balance"}}</th>
                      <th>{{i18n "discourse_cosmetics_store.admin.wallet.columns.debt"}}</th>
                    </tr>
                  </thead>
                  <tbody class="d-table__body">
                    {{#each this.walletResult.wallet.ledger as |entry|}}
                      <tr class="d-table__row">
                        <td class="d-table__cell --overview">
                          <span class={{if entry.credit "is-credit" "is-debit"}}>{{entry.amount}}</span>
                        </td>
                        <td class="d-table__cell --detail">
                          <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.wallet.columns.reason"}}</div>
                          {{entry.reason}}
                        </td>
                        <td class="d-table__cell --detail">
                          <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.wallet.columns.type"}}</div>
                          {{entry.entry_type}}
                        </td>
                        <td class="d-table__cell --detail">
                          <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.wallet.columns.balance"}}</div>
                          {{entry.balance_after}}
                        </td>
                        <td class="d-table__cell --detail">
                          <div class="d-table__mobile-label">{{i18n "discourse_cosmetics_store.admin.wallet.columns.debt"}}</div>
                          {{if entry.debt_after entry.debt_after "—"}}
                        </td>
                      </tr>
                    {{/each}}
                  </tbody>
                </table>
              </div>
            {{else}}
              <AdminConfigAreaEmptyList
                @emptyLabel="discourse_cosmetics_store.admin.wallet.no_ledger"
              />
            {{/if}}
          </section>
        </div>
      {{/if}}
    </section>
  </template>
}
