import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DModal from "discourse/ui-kit/d-modal";

export default class CosmeticsStoreOrbPurchases extends Component {
  @tracked selectedPackage = null;
  @tracked selectedProvider = "";
  @tracked busy = false;
  @tracked billing = {
    name: "",
    address: "",
    phone: "",
    city: "",
    country: "Türkiye",
    zip_code: "",
    identity_number: "",
  };

  get packages() {
    return this.args.packages ?? [];
  }

  get providers() {
    return this.args.providers ?? [];
  }

  get availableProviders() {
    const allowed = new Set(this.selectedPackage?.providers || []);
    return this.providers.filter((provider) => allowed.has(provider.id));
  }

  get activeProvider() {
    return this.providers.find((provider) => provider.id === this.selectedProvider);
  }

  get requiresBilling() {
    return Boolean(this.activeProvider?.requires_billing);
  }

  get requiresIdentity() {
    return Boolean(this.activeProvider?.requires_identity);
  }

  @action
  open(packageRow) {
    if (!this.args.viewer?.logged_in) {
      window.location.assign("/login?return_path=%2Fstore%2Forbs");
      return;
    }
    this.selectedPackage = packageRow;
    this.selectedProvider = packageRow.providers?.[0] || "";
  }

  @action
  close() {
    if (!this.busy) {
      this.selectedPackage = null;
    }
  }

  @action
  chooseProvider(providerId) {
    this.selectedProvider = providerId;
  }

  @action
  updateBilling(field, event) {
    this.billing = { ...this.billing, [field]: event.target.value };
  }

  @action
  async checkout(event) {
    event?.preventDefault();
    if (this.busy || !this.selectedPackage || !this.selectedProvider) {
      return;
    }
    this.busy = true;
    try {
      const response = await ajax("/cosmetics-store/payments.json", {
        type: "POST",
        data: {
          orb_package_id: this.selectedPackage.id,
          provider: this.selectedProvider,
          ...this.billing,
        },
      });
      window.location.assign(response.checkout_url);
    } catch (error) {
      popupAjaxError(error);
      this.busy = false;
    }
  }

  <template>
    <section id="orb-yukle" class="cstore-cash-packages" tabindex="-1">
      <div class="cstore-section__heading">
        <div><p class="cstore-eyebrow">GÜVENLİ ÖDEME</p><h2>{{@settings.currency_name}} yükle</h2></div>
        <p>Kart bilgilerin forum sunucusuna gönderilmez; ödeme seçtiğin sağlayıcının güvenli sayfasında tamamlanır.</p>
      </div>
      {{#if this.packages.length}}
        <div class="cstore-cash-packages__grid">
          {{#each this.packages as |packageRow|}}
            <article class={{if packageRow.featured "is-featured"}}>
              {{#if packageRow.featured}}<span class="cstore-cash-packages__badge">ÖNERİLEN</span>{{/if}}
              <div class="cstore-cash-packages__orb"><i>{{@settings.currency_symbol}}</i><strong>{{packageRow.orb_amount}}</strong></div>
              <h3>{{packageRow.name}}</h3>
              <p>{{packageRow.description}}</p>
              <button type="button" data-testid="orb-package-open" {{on "click" (fn this.open packageRow)}}>
                {{packageRow.price}} {{packageRow.currency}} ile yükle
              </button>
            </article>
          {{/each}}
        </div>
      {{else}}
        <div class="cstore-cash-packages__empty" role="status">
          <span aria-hidden="true">{{@settings.currency_symbol}}</span>
          <div>
            <strong>Orb yükleme şu anda kapalı</strong>
            {{#if @viewer.is_admin}}
              <p>Ödeme ayarlarından Shopier'i etkinleştirip Ödemeler sekmesinde en az bir Orb paketini yayına alın.</p>
            {{else}}
              <p>Şu anda satın alınabilir aktif bir Orb paketi bulunmuyor. Paketler açıldığında burada görünecek.</p>
            {{/if}}
          </div>
        </div>
      {{/if}}
    </section>

    {{#if @payments.length}}
      <section class="cstore-payment-history">
        <div><p class="cstore-eyebrow">ÖDEME GEÇMİŞİ</p><h2>Son yüklemeler</h2></div>
        <div>
          {{#each @payments as |payment|}}
            <article><strong>+{{payment.orb_amount}} {{@settings.currency_symbol}}{{#if payment.refunded_orb_amount}} <small>−{{payment.refunded_orb_amount}} iade</small>{{/if}}</strong><span>{{payment.provider}}</span><i class="is-{{payment.status}}">{{payment.status}}</i></article>
          {{/each}}
        </div>
      </section>
    {{/if}}

    {{#if this.selectedPackage}}
      <DModal
        @title={{this.selectedPackage.name}}
        @closeModal={{this.close}}
        @bodyClass="cstore-payment-dialog__body"
        @inline={{@inline}}
        class="cstore-payment-dialog --large"
      >
        <:body>
          <form class="cstore-payment-dialog__window" {{on "submit" this.checkout}}>
            <p class="cstore-eyebrow">ORB YÜKLE</p>
            <div class="cstore-payment-dialog__summary"><strong>{{@settings.currency_symbol}} {{this.selectedPackage.orb_amount}}</strong><span>{{this.selectedPackage.price}} {{this.selectedPackage.currency}}</span></div>
            <fieldset><legend>Ödeme yöntemi</legend><div class="cstore-payment-providers">{{#each this.availableProviders as |provider|}}<button class={{if (eq provider.id this.selectedProvider) "is-active"}} type="button" aria-pressed={{eq provider.id this.selectedProvider}} data-testid="payment-provider" {{on "click" (fn this.chooseProvider provider.id)}}>{{provider.label}}</button>{{/each}}</div></fieldset>
            {{#if this.requiresBilling}}
              <fieldset class="cstore-payment-billing">
                <legend>Sağlayıcı için gerekli fatura bilgileri</legend>
                <label>Ad soyad<input required value={{this.billing.name}} autocomplete="name" {{on "input" (fn this.updateBilling "name")}} /></label>
                <label>Telefon<input required value={{this.billing.phone}} autocomplete="tel" {{on "input" (fn this.updateBilling "phone")}} /></label>
                <label class="is-wide">Adres<input required value={{this.billing.address}} autocomplete="street-address" {{on "input" (fn this.updateBilling "address")}} /></label>
                <label>Şehir<input required value={{this.billing.city}} autocomplete="address-level2" {{on "input" (fn this.updateBilling "city")}} /></label>
                <label>Ülke<input required value={{this.billing.country}} autocomplete="country-name" {{on "input" (fn this.updateBilling "country")}} /></label>
                <label>Posta kodu<input value={{this.billing.zip_code}} autocomplete="postal-code" {{on "input" (fn this.updateBilling "zip_code")}} /></label>
                {{#if this.requiresIdentity}}<label>Kimlik numarası<input required inputmode="numeric" maxlength="20" value={{this.billing.identity_number}} autocomplete="off" {{on "input" (fn this.updateBilling "identity_number")}} /></label>{{/if}}
              </fieldset>
            {{/if}}
            <p class="cstore-payment-dialog__notice">Tutar, para birimi ve sağlayıcı imzası sunucuda tekrar doğrulanmadan bakiye yüklenmez.</p>
            <button class="cstore-buy" data-testid="payment-submit" type="submit" disabled={{this.busy}}>{{if this.busy "Güvenli ödeme hazırlanıyor…" "Ödemeye devam et"}}</button>
          </form>
        </:body>
      </DModal>
    {{/if}}
  </template>
}
