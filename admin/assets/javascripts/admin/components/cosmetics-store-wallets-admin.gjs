import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

export default class CosmeticsStoreWalletsAdmin extends Component {
  @tracked walletUsername = "";
  @tracked walletAmount = 0;
  @tracked walletReason = "";
  @tracked walletResult = null;
  @tracked status = null;

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
  }

  @action
  updateWalletUsername(event) {
    this.walletUsername = event.target.value;
  }

  @action
  updateWalletAmount(event) {
    this.walletAmount = Number.parseInt(event.target.value || "0", 10);
  }

  @action
  updateWalletReason(event) {
    this.walletReason = event.target.value;
  }

  @action
  async findWallet(event) {
    event?.preventDefault();
    if (!this.walletUsername.trim()) {
      return;
    }

    try {
      this.walletResult = await ajax(
        `${ADMIN_API_BASE}/wallet.json?username=${encodeURIComponent(this.walletUsername.trim())}`
      );
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async adjustWallet(event) {
    event?.preventDefault();
    if (
      !this.walletResult ||
      !this.walletAmount ||
      !this.walletReason.trim()
    ) {
      return;
    }

    try {
      this.walletResult = await ajax(`${ADMIN_API_BASE}/wallet/adjust.json`, {
        type: "POST",
        data: {
          username: this.walletResult.user.username,
          amount: this.walletAmount,
          reason: this.walletReason.trim(),
        },
      });
      this.walletAmount = 0;
      this.walletReason = "";
      this.status =
        "Cüzdan bakiyesi güncellendi ve işlem defterine kaydedildi.";
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <section class="cstore-admin cstore-admin__section cstore-admin-wallets">
      <div class="cstore-admin__section-heading">
        <div>
          <h2>Kullanıcı cüzdanları</h2>
          <p>Her manuel işlem değiştirilemez işlem defterine, yapan yöneticiyle birlikte kaydedilir.</p>
        </div>
      </div>

      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      <form class="cstore-wallet-search" {{on "submit" this.findWallet}}>
        <label>Kullanıcı adı<input value={{this.walletUsername}} {{on "input" this.updateWalletUsername}} placeholder="kullanici" /></label>
        <button class="btn btn-primary" type="submit">Cüzdanı getir</button>
      </form>

      {{#if this.walletResult}}
        <div class="cstore-wallet-card">
          <header>
            <img src={{this.walletResult.user.avatar_url}} alt="" />
            <div><strong>{{this.walletResult.user.name}}</strong><span>@{{this.walletResult.user.username}}</span></div>
            <b>{{this.settings.currency_symbol}} {{this.walletResult.wallet.balance}}</b>
          </header>

          {{#if this.walletResult.wallet.debt}}
            <div class="cstore-wallet-card__debt">
              <strong>{{this.walletResult.wallet.debt}} {{this.settings.currency_symbol}} iade borcu</strong>
              <span>Yeni Orb kredileri önce bu borcu kapatır.</span>
            </div>
          {{/if}}

          <div class="cstore-wallet-card__stats">
            <span><strong>{{this.walletResult.wallet.lifetime_earned}}</strong><small>Toplam kazanılan</small></span>
            <span><strong>{{this.walletResult.wallet.lifetime_spent}}</strong><small>Toplam harcanan</small></span>
            {{#if this.walletResult.wallet.debt}}
              <span><strong>{{this.walletResult.wallet.debt}}</strong><small>İade borcu</small></span>
            {{/if}}
          </div>

          <form {{on "submit" this.adjustWallet}}>
            <label>Miktar<input type="number" value={{this.walletAmount}} {{on "input" this.updateWalletAmount}} placeholder="+100 veya -100" /></label>
            <label>Neden<input maxlength="500" value={{this.walletReason}} {{on "input" this.updateWalletReason}} placeholder="İşlem açıklaması" /></label>
            <button class="btn btn-primary" type="submit">Bakiyeyi güncelle</button>
          </form>

          <section>
            <h3>Son hareketler</h3>
            {{#each this.walletResult.wallet.ledger as |entry|}}
              <article>
                <span class={{if entry.credit "is-credit" "is-debit"}}>{{entry.amount}}</span>
                <div>
                  <strong>{{entry.reason}}</strong>
                  <small>{{entry.entry_type}} · bakiye {{entry.balance_after}}{{#if entry.debt_after}} · borç {{entry.debt_after}}{{/if}}</small>
                </div>
              </article>
            {{else}}
              <p>Henüz işlem yok.</p>
            {{/each}}
          </section>
        </div>
      {{/if}}
    </section>
  </template>
}
