import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

export default class CosmeticsStorePaymentsAdmin extends Component {
  @tracked packages = this.args.packages ?? [];
  @tracked editing = null;
  @tracked saving = false;
  @tracked status = null;

  get providers() {
    return this.args.providers ?? [];
  }

  get payments() {
    return this.args.payments ?? [];
  }

  get providerRows() {
    const selected = new Set(this.editing?.providers || []);
    return this.providers.map((provider) => ({ ...provider, selected: selected.has(provider.id) }));
  }

  @action
  newPackage() {
    this.editing = {
      name: "",
      description: "",
      orb_amount: 100,
      price: "49.90",
      currency: "TRY",
      sort_order: 0,
      enabled: true,
      featured: false,
      providers: this.providers.filter((provider) => provider.enabled).map((provider) => provider.id),
      shopier_product_id: "",
      shopier_checkout_url: "",
    };
  }

  @action
  editPackage(packageRow) {
    this.editing = { ...packageRow, providers: [...(packageRow.providers || [])] };
  }

  @action
  cancel() {
    this.editing = null;
  }

  @action
  update(field, event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    if (["orb_amount", "sort_order"].includes(field)) {
      value = Number.parseInt(value || "0", 10);
    }
    this.editing = { ...this.editing, [field]: value };
  }

  @action
  toggleProvider(provider, event) {
    const selected = new Set(this.editing.providers || []);
    if (event.target.checked) {
      selected.add(provider.id);
    } else {
      selected.delete(provider.id);
    }
    this.editing = { ...this.editing, providers: [...selected] };
  }

  @action
  async save(event) {
    event?.preventDefault();
    if (this.saving) {
      return;
    }
    const priceMinor = Math.round(Number.parseFloat(String(this.editing.price).replace(",", ".")) * 100);
    if (!Number.isFinite(priceMinor) || priceMinor <= 0) {
      this.status = "Geçerli bir satış fiyatı girin.";
      return;
    }
    this.saving = true;
    const payload = { ...this.editing, price_minor: priceMinor };
    const url = this.editing.id
      ? `${ADMIN_API_BASE}/orb-packages/${this.editing.id}.json`
      : `${ADMIN_API_BASE}/orb-packages.json`;
    try {
      const saved = await ajax(url, {
        type: this.editing.id ? "PUT" : "POST",
        data: { orb_package: payload },
      });
      this.packages = this.editing.id
        ? this.packages.map((row) => (row.id === saved.id ? saved : row))
        : [...this.packages, saved];
      this.editing = null;
      this.status = "Orb paketi kaydedildi.";
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async remove(packageRow) {
    if (!window.confirm(`“${packageRow.name}” paketini kaldırmak istediğine emin misin?`)) {
      return;
    }
    try {
      const response = await ajax(`${ADMIN_API_BASE}/orb-packages/${packageRow.id}.json`, { type: "DELETE" });
      if (response?.disabled_instead_of_deleted) {
        this.packages = this.packages.map((row) => (row.id === packageRow.id ? response : row));
        this.status = "Ödeme geçmişi olan paket silinmedi, pasifleştirildi.";
      } else {
        this.packages = this.packages.filter((row) => row.id !== packageRow.id);
        this.status = "Orb paketi silindi.";
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <section class="cstore-admin__section cstore-admin-payments">
      <div class="cstore-admin__section-heading"><div><h2>Orb satışı ve ödeme sağlayıcıları</h2><p>Anahtarlar yalnızca eklenti ayarlarında sunucuda saklanır. Orb teslimatı yalnızca doğrulanmış, idempotent bildirimden sonra yapılır.</p></div><button class="btn btn-primary" type="button" {{on "click" this.newPackage}}>+ Orb paketi</button></div>
      {{#if this.status}}<div class="cstore-admin__status">{{this.status}}</div>{{/if}}

      <div class="cstore-provider-status">
        {{#each this.providers as |provider|}}
          <article class={{if provider.enabled "is-ready" "is-off"}}><header><strong>{{provider.label}}</strong><span>{{if provider.enabled "Hazır" "Kapalı / eksik"}}</span></header>{{#if provider.webhook_url}}<label>Webhook URL<input readonly value={{provider.webhook_url}} /></label>{{/if}}{{#if provider.osb_callback_url}}<label>Shopier OSB Bildirim URL<input readonly value={{provider.osb_callback_url}} /></label>{{/if}}{{#if provider.callback_url}}<label>Callback URL<input readonly value={{provider.callback_url}} /></label>{{/if}}</article>
        {{/each}}
      </div>

      {{#if this.editing}}
        <form class="cstore-admin-form" {{on "submit" this.save}}>
          <div class="cstore-admin-form__title"><div><h3>{{if this.editing.id "Orb paketini düzenle" "Yeni Orb paketi"}}</h3><p>Fiyat, işlem oluşturulduğu anda değiştirilemez ödeme anlık görüntüsüne çevrilir.</p></div><button type="button" {{on "click" this.cancel}}>×</button></div>
          <div class="cstore-admin-form__grid">
            <label>Paket adı<input required maxlength="120" value={{this.editing.name}} {{on "input" (fn this.update "name")}} /></label>
            <label>Orb miktarı<input required min="1" type="number" value={{this.editing.orb_amount}} {{on "input" (fn this.update "orb_amount")}} /></label>
            <label>Satış fiyatı<input required inputmode="decimal" value={{this.editing.price}} {{on "input" (fn this.update "price")}} placeholder="49.90" /></label>
            <label>Para birimi<select value={{this.editing.currency}} {{on "change" (fn this.update "currency")}}><option value="TRY">TRY</option><option value="USD">USD</option><option value="EUR">EUR</option><option value="GBP">GBP</option></select></label>
            <label>Sıra<input min="0" type="number" value={{this.editing.sort_order}} {{on "input" (fn this.update "sort_order")}} /></label>
            <label class="is-wide">Açıklama<textarea maxlength="500" rows="3" value={{this.editing.description}} {{on "input" (fn this.update "description")}}></textarea></label>
            <label class="is-wide">Shopier ürün bağlantısı<input type="url" value={{this.editing.shopier_checkout_url}} {{on "input" (fn this.update "shopier_checkout_url")}} placeholder="https://www.shopier.com/..." /></label>
            <label>Shopier ürün kimliği<input maxlength="190" value={{this.editing.shopier_product_id}} {{on "input" (fn this.update "shopier_product_id")}} /></label>
          </div>
          <fieldset class="cstore-admin-provider-flags"><legend>Bu pakette kabul edilen sağlayıcılar</legend>{{#each this.providerRows as |provider|}}<label><input type="checkbox" checked={{provider.selected}} disabled={{if provider.enabled false true}} {{on "change" (fn this.toggleProvider provider)}} />{{provider.label}} <small>{{if provider.enabled "yapılandırıldı" "önce ayarlardan yapılandır"}}</small></label>{{/each}}</fieldset>
          <div class="cstore-admin-flags"><label><input type="checkbox" checked={{this.editing.enabled}} {{on "change" (fn this.update "enabled")}} /> Yayında</label><label><input type="checkbox" checked={{this.editing.featured}} {{on "change" (fn this.update "featured")}} /> Önerilen paket</label></div>
          <div class="cstore-admin-form__actions"><button class="btn" type="button" {{on "click" this.cancel}}>İptal</button><button class="btn btn-primary" type="submit" disabled={{this.saving}}>{{if this.saving "Kaydediliyor…" "Paketi kaydet"}}</button></div>
        </form>
      {{/if}}

      <div class="cstore-admin-table-wrap"><table class="cstore-admin-table"><thead><tr><th>Paket</th><th>Orb</th><th>Fiyat</th><th>Sağlayıcılar</th><th>Durum</th><th>İşlem</th></tr></thead><tbody>{{#each this.packages as |packageRow|}}<tr><td><strong>{{packageRow.name}}</strong><small>{{packageRow.payment_count}} ödeme</small></td><td>{{packageRow.orb_amount}}</td><td>{{packageRow.price}} {{packageRow.currency}}</td><td>{{packageRow.providers.length}}</td><td>{{if packageRow.enabled "Yayında" "Kapalı"}}</td><td><button type="button" {{on "click" (fn this.editPackage packageRow)}}>Düzenle</button><button class="is-danger" type="button" {{on "click" (fn this.remove packageRow)}}>Sil</button></td></tr>{{else}}<tr><td colspan="6">Henüz gerçek para ile satılan Orb paketi yok.</td></tr>{{/each}}</tbody></table></div>

      <div class="cstore-admin-payments__history"><h3>Son 100 ödeme</h3><div class="cstore-admin-table-wrap"><table class="cstore-admin-table"><thead><tr><th>Kullanıcı</th><th>Paket</th><th>Sağlayıcı</th><th>Tutar</th><th>Orb</th><th>Durum</th></tr></thead><tbody>{{#each this.payments as |payment|}}<tr><td>@{{payment.username}}</td><td>{{payment.package_name}}</td><td>{{payment.provider}}</td><td>{{payment.amount}} {{payment.currency}}</td><td>{{payment.orb_amount}}</td><td><span class="is-payment-{{payment.status}}">{{payment.status}}</span>{{#if payment.failure_message}}<small>{{payment.failure_message}}</small>{{/if}}</td></tr>{{else}}<tr><td colspan="6">Henüz ödeme kaydı yok.</td></tr>{{/each}}</tbody></table></div></div>
    </section>
  </template>
}
