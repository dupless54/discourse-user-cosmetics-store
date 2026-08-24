import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import CosmeticsStorePaymentsAdmin from "./cosmetics-store-payments-admin";

const ADMIN_API_BASE = "/admin/plugins/user-cosmetics-store";

const EMPTY_PRODUCT = {
  name: "",
  slug: "",
  description: "",
  product_type: "item",
  price: 0,
  card_image_url: "",
  hero_image_url: "",
  preview_background_url: "",
  rarity_label: "",
  rarity_color: "",
  tags_csv: "",
  sort_order: 0,
  enabled: true,
  featured: false,
  editor_pick: false,
  exclusive: true,
  available_from: "",
  available_until: "",
  cosmetic_item_ids: [],
};

const EMPTY_MISSION = {
  key: "",
  name: "",
  description: "",
  metric: "posts_created",
  target: 1,
  reward: 25,
  icon: "✦",
  sort_order: 0,
  enabled: true,
  available_from: "",
  available_until: "",
};

export default class CosmeticsStoreAdminPage extends Component {
  @tracked products = this.args.model?.products ?? [];
  @tracked cosmeticItems = this.args.model?.cosmetic_items ?? [];
  @tracked missions = this.args.model?.missions ?? [];
  @tracked missionMetrics = this.args.model?.mission_metrics ?? [];
  @tracked activeTab = "products";
  @tracked editingProduct = null;
  @tracked editingMission = null;
  @tracked saving = false;
  @tracked status = null;
  @tracked walletUsername = "";
  @tracked walletAmount = 0;
  @tracked walletReason = "";
  @tracked walletResult = null;

  get settings() {
    return this.args.model?.settings ?? { currency_name: "Orbs", currency_symbol: "◈" };
  }

  get paymentPackageCount() {
    return this.args.model?.orb_packages?.length ?? 0;
  }

  get groupedCosmeticItems() {
    const labels = {
      avatar_frame: "Avatar çerçeveleri",
      nameplate: "İsim plakaları",
      card_decoration: "Kart dekorasyonları",
      profile_effect: "Profil efektleri",
    };
    const selected = new Set(this.editingProduct?.cosmetic_item_ids || []);
    return Object.entries(labels).map(([kind, label]) => ({
      kind,
      label,
      items: this.cosmeticItems
        .filter((item) => item.kind === kind)
        .map((item) => ({ ...item, selected: selected.has(item.id), disabled: !item.enabled })),
    }));
  }

  @action
  setTab(tab) {
    this.activeTab = tab;
    this.status = null;
  }

  @action
  newProduct() {
    this.editingProduct = { ...EMPTY_PRODUCT, cosmetic_item_ids: [] };
    this.status = null;
  }

  @action
  editProduct(product) {
    this.editingProduct = {
      ...product,
      cosmetic_item_ids: [...(product.cosmetic_item_ids || [])],
    };
    this.status = null;
  }

  @action
  cancelProduct() {
    this.editingProduct = null;
  }

  @action
  updateProduct(field, event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    if (["price", "sort_order"].includes(field)) {
      value = Number.parseInt(value || "0", 10);
    }
    const next = { ...this.editingProduct, [field]: value };
    if (field === "product_type" && value === "item" && next.cosmetic_item_ids.length > 1) {
      next.cosmetic_item_ids = next.cosmetic_item_ids.slice(0, 1);
    }
    this.editingProduct = next;
  }

  @action
  toggleCosmetic(item, event) {
    const ids = new Set(this.editingProduct.cosmetic_item_ids || []);
    if (event.target.checked) {
      if (this.editingProduct.product_type === "item") {
        ids.clear();
      }
      ids.add(item.id);
    } else {
      ids.delete(item.id);
    }
    this.editingProduct = { ...this.editingProduct, cosmetic_item_ids: [...ids] };
  }

  @action
  async saveProduct(event) {
    event?.preventDefault();
    if (this.saving) {
      return;
    }
    this.saving = true;
    const product = this.editingProduct;
    const payload = {
      ...product,
      tags: String(product.tags_csv || "")
        .split(",")
        .map((tag) => tag.trim())
        .filter(Boolean),
      available_from: product.available_from || null,
      available_until: product.available_until || null,
    };
    const url = product.id
      ? `${ADMIN_API_BASE}/products/${product.id}.json`
      : `${ADMIN_API_BASE}/products.json`;
    try {
      const saved = await ajax(url, {
        type: product.id ? "PUT" : "POST",
        data: { product: payload },
      });
      this.products = product.id
        ? this.products.map((row) => (row.id === saved.id ? saved : row))
        : [saved, ...this.products];
      this.editingProduct = null;
      this.status = "Ürün kaydedildi ve vitrin önbelleği yenilendi.";
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async deleteProduct(product) {
    if (!window.confirm(`“${product.name}” ürününü silmek istediğine emin misin?`)) {
      return;
    }
    try {
      await ajax(`${ADMIN_API_BASE}/products/${product.id}.json`, {
        type: "DELETE",
      });
      this.products = this.products.filter((row) => row.id !== product.id);
      this.status = "Ürün silindi.";
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  newMission() {
    this.editingMission = { ...EMPTY_MISSION };
    this.status = null;
  }

  @action
  editMission(mission) {
    this.editingMission = { ...mission };
    this.status = null;
  }

  @action
  cancelMission() {
    this.editingMission = null;
  }

  @action
  updateMission(field, event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    if (["target", "reward", "sort_order"].includes(field)) {
      value = Number.parseInt(value || "0", 10);
    }
    this.editingMission = { ...this.editingMission, [field]: value };
  }

  @action
  async saveMission(event) {
    event?.preventDefault();
    if (this.saving) {
      return;
    }
    this.saving = true;
    const mission = this.editingMission;
    const payload = {
      ...mission,
      available_from: mission.available_from || null,
      available_until: mission.available_until || null,
    };
    const url = mission.id
      ? `${ADMIN_API_BASE}/missions/${mission.id}.json`
      : `${ADMIN_API_BASE}/missions.json`;
    try {
      const saved = await ajax(url, {
        type: mission.id ? "PUT" : "POST",
        data: { mission: payload },
      });
      this.missions = mission.id
        ? this.missions.map((row) => (row.id === saved.id ? saved : row))
        : [...this.missions, saved];
      this.editingMission = null;
      this.status = "Görev kaydedildi.";
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async deleteMission(mission) {
    if (!window.confirm(`“${mission.name}” görevini kaldırmak istediğine emin misin?`)) {
      return;
    }
    try {
      await ajax(`${ADMIN_API_BASE}/missions/${mission.id}.json`, {
        type: "DELETE",
      });
      if (mission.claim_count > 0) {
        this.missions = this.missions.map((row) =>
          row.id === mission.id ? { ...row, enabled: false } : row
        );
      } else {
        this.missions = this.missions.filter((row) => row.id !== mission.id);
      }
      this.status = mission.claim_count > 0 ? "Geçmişi olan görev pasifleştirildi." : "Görev silindi.";
    } catch (error) {
      popupAjaxError(error);
    }
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
    if (!this.walletResult || !this.walletAmount || !this.walletReason.trim()) {
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
      this.status = "Cüzdan bakiyesi güncellendi ve işlem defterine kaydedildi.";
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <div class="cstore-admin">
      <header class="cstore-admin__header"><div><p>DISCOURSE USER COSMETICS ENTEGRASYONU</p><h1>Kozmetik Mağazası</h1><span>Vitrini, Orbs görevlerini ve kullanıcı cüzdanlarını tek yerden yönet.</span></div><a href="/store" target="_blank" rel="noopener noreferrer">Mağazayı aç ↗</a></header>

      <nav class="cstore-admin__tabs" aria-label="Mağaza yönetimi">
        <button class={{if (eq this.activeTab "products") "is-active"}} type="button" {{on "click" (fn this.setTab "products")}}>Ürünler <span>{{this.products.length}}</span></button>
        <button class={{if (eq this.activeTab "missions") "is-active"}} type="button" {{on "click" (fn this.setTab "missions")}}>Görevler <span>{{this.missions.length}}</span></button>
        <button class={{if (eq this.activeTab "payments") "is-active"}} type="button" {{on "click" (fn this.setTab "payments")}}>Ödemeler <span>{{this.paymentPackageCount}}</span></button>
        <button class={{if (eq this.activeTab "wallets") "is-active"}} type="button" {{on "click" (fn this.setTab "wallets")}}>Cüzdanlar</button>
      </nav>

      {{#if this.status}}<div class="cstore-admin__status" role="status">✓ {{this.status}}</div>{{/if}}

      {{#if (eq this.activeTab "products")}}
        <section class="cstore-admin__section">
          <div class="cstore-admin__section-heading"><div><h2>Mağaza ürünleri</h2><p>Tek bir kozmetiği veya birden fazla öğeyi paket halinde yayınla.</p></div><button class="btn btn-primary" type="button" {{on "click" this.newProduct}}>+ Yeni ürün</button></div>

          {{#if this.editingProduct}}
            <form class="cstore-admin-form" {{on "submit" this.saveProduct}}>
              <div class="cstore-admin-form__title"><div><h3>{{if this.editingProduct.id "Ürünü düzenle" "Yeni ürün"}}</h3><p>Ürün exclusive ise, mağazadan alınana kadar kozmetik seçicide kilitli kalır.</p></div><button type="button" {{on "click" this.cancelProduct}}>×</button></div>
              <div class="cstore-admin-form__grid">
                <label>Ürün adı<input required maxlength="120" value={{this.editingProduct.name}} {{on "input" (fn this.updateProduct "name")}} /></label>
                <label>Slug<input maxlength="140" value={{this.editingProduct.slug}} {{on "input" (fn this.updateProduct "slug")}} placeholder="Boşsa otomatik oluşur" /></label>
                <label>Ürün türü<select value={{this.editingProduct.product_type}} {{on "change" (fn this.updateProduct "product_type")}}><option value="item">Tekli kozmetik</option><option value="bundle">Paket</option></select></label>
                <label>Orbs fiyatı<input required min="0" type="number" value={{this.editingProduct.price}} {{on "input" (fn this.updateProduct "price")}} /></label>
                <label>Nadirlik etiketi<input maxlength="40" value={{this.editingProduct.rarity_label}} {{on "input" (fn this.updateProduct "rarity_label")}} placeholder="Efsanevi" /></label>
                <label>Nadirlik rengi<input type="color" value={{this.editingProduct.rarity_color}} {{on "input" (fn this.updateProduct "rarity_color")}} /></label>
                <label>Sıra<input min="0" type="number" value={{this.editingProduct.sort_order}} {{on "input" (fn this.updateProduct "sort_order")}} /></label>
                <label>Etiketler<input value={{this.editingProduct.tags_csv}} {{on "input" (fn this.updateProduct "tags_csv")}} placeholder="anime, neon, oyun" /></label>
                <label class="is-wide">Kart görseli URL<input type="url" value={{this.editingProduct.card_image_url}} {{on "input" (fn this.updateProduct "card_image_url")}} /></label>
                <label class="is-wide">Hero görseli URL<input type="url" value={{this.editingProduct.hero_image_url}} {{on "input" (fn this.updateProduct "hero_image_url")}} /></label>
                <label class="is-wide">Önizleme arka planı URL<input type="url" value={{this.editingProduct.preview_background_url}} {{on "input" (fn this.updateProduct "preview_background_url")}} /></label>
                <label>Başlangıç<input type="datetime-local" value={{this.editingProduct.available_from}} {{on "input" (fn this.updateProduct "available_from")}} /></label>
                <label>Bitiş<input type="datetime-local" value={{this.editingProduct.available_until}} {{on "input" (fn this.updateProduct "available_until")}} /></label>
                <label class="is-wide">Açıklama<textarea rows="4" maxlength="4000" value={{this.editingProduct.description}} {{on "input" (fn this.updateProduct "description")}}></textarea></label>
              </div>
              <div class="cstore-admin-flags">
                <label><input type="checkbox" checked={{this.editingProduct.enabled}} {{on "change" (fn this.updateProduct "enabled")}} /> Yayında</label>
                <label><input type="checkbox" checked={{this.editingProduct.featured}} {{on "change" (fn this.updateProduct "featured")}} /> Öne çıkan</label>
                <label><input type="checkbox" checked={{this.editingProduct.editor_pick}} {{on "change" (fn this.updateProduct "editor_pick")}} /> Editör seçimi</label>
                <label><input type="checkbox" checked={{this.editingProduct.exclusive}} {{on "change" (fn this.updateProduct "exclusive")}} /> Satın alma gerektirir</label>
              </div>
              <fieldset class="cstore-admin-items"><legend>Paketteki kozmetikler</legend><p>{{if (eq this.editingProduct.product_type "item") "Tam olarak bir öğe seç." "En az iki öğe seç."}}</p>{{#each this.groupedCosmeticItems as |group|}}<section><h4>{{group.label}}</h4><div>{{#each group.items as |item|}}<label class={{if item.enabled "" "is-disabled-item"}}><input type={{if (eq this.editingProduct.product_type "item") "radio" "checkbox"}} name={{if (eq this.editingProduct.product_type "item") "cosmetic-item" "cosmetic-items"}} checked={{item.selected}} disabled={{item.disabled}} {{on "change" (fn this.toggleCosmetic item)}} /><span>{{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{else}}<i>✦</i>{{/if}}<b>{{item.name}}</b><small>{{item.rarity_label}}</small></span></label>{{/each}}</div></section>{{/each}}</fieldset>
              <div class="cstore-admin-form__actions"><button class="btn" type="button" {{on "click" this.cancelProduct}}>İptal</button><button class="btn btn-primary" type="submit" disabled={{this.saving}}>{{if this.saving "Kaydediliyor…" "Ürünü kaydet"}}</button></div>
            </form>
          {{/if}}

          <div class="cstore-admin-table-wrap"><table class="cstore-admin-table"><thead><tr><th>Ürün</th><th>Tür</th><th>İçerik</th><th>Fiyat</th><th>Vitrin</th><th>Satış</th><th>İşlemler</th></tr></thead><tbody>{{#each this.products as |product|}}<tr><td><strong>{{product.name}}</strong><small>/{{product.slug}}</small></td><td>{{if (eq product.product_type "bundle") "Paket" "Tekli"}}</td><td>{{product.item_names.length}} öğe</td><td>{{this.settings.currency_symbol}} {{product.price}}</td><td><span class={{if product.enabled "is-on" "is-off"}}>{{if product.enabled "Yayında" "Kapalı"}}</span>{{#if product.editor_pick}} <span>Editör</span>{{/if}}</td><td>{{product.purchase_count}}</td><td><button type="button" {{on "click" (fn this.editProduct product)}}>Düzenle</button><button class="is-danger" type="button" {{on "click" (fn this.deleteProduct product)}}>Sil</button></td></tr>{{else}}<tr><td colspan="7">Henüz mağaza ürünü yok.</td></tr>{{/each}}</tbody></table></div>
        </section>
      {{else if (eq this.activeTab "missions")}}
        <section class="cstore-admin__section">
          <div class="cstore-admin__section-heading"><div><h2>Orbs görevleri</h2><p>İlerleme tarayıcıdan değil, Discourse kullanıcı istatistiklerinden doğrulanır.</p></div><button class="btn btn-primary" type="button" {{on "click" this.newMission}}>+ Yeni görev</button></div>
          {{#if this.editingMission}}
            <form class="cstore-admin-form cstore-admin-form--mission" {{on "submit" this.saveMission}}><div class="cstore-admin-form__title"><h3>{{if this.editingMission.id "Görevi düzenle" "Yeni görev"}}</h3><button type="button" {{on "click" this.cancelMission}}>×</button></div><div class="cstore-admin-form__grid"><label>Görev adı<input required value={{this.editingMission.name}} {{on "input" (fn this.updateMission "name")}} /></label><label>Anahtar<input value={{this.editingMission.key}} {{on "input" (fn this.updateMission "key")}} placeholder="otomatik-anahtar" /></label><label>Metrik<select value={{this.editingMission.metric}} {{on "change" (fn this.updateMission "metric")}}>{{#each this.missionMetrics as |metric|}}<option value={{metric.value}}>{{metric.label}}</option>{{/each}}</select></label><label>Hedef<input min="1" type="number" value={{this.editingMission.target}} {{on "input" (fn this.updateMission "target")}} /></label><label>Ödül<input min="0" type="number" value={{this.editingMission.reward}} {{on "input" (fn this.updateMission "reward")}} /></label><label>Simge<input maxlength="20" value={{this.editingMission.icon}} {{on "input" (fn this.updateMission "icon")}} /></label><label>Sıra<input min="0" type="number" value={{this.editingMission.sort_order}} {{on "input" (fn this.updateMission "sort_order")}} /></label><label class="cstore-admin-checkbox"><input type="checkbox" checked={{this.editingMission.enabled}} {{on "change" (fn this.updateMission "enabled")}} /> Etkin</label><label>Başlangıç<input type="datetime-local" value={{this.editingMission.available_from}} {{on "input" (fn this.updateMission "available_from")}} /></label><label>Bitiş<input type="datetime-local" value={{this.editingMission.available_until}} {{on "input" (fn this.updateMission "available_until")}} /></label><label class="is-wide">Açıklama<textarea rows="3" maxlength="500" value={{this.editingMission.description}} {{on "input" (fn this.updateMission "description")}}></textarea></label></div><div class="cstore-admin-form__actions"><button class="btn" type="button" {{on "click" this.cancelMission}}>İptal</button><button class="btn btn-primary" type="submit" disabled={{this.saving}}>Kaydet</button></div></form>
          {{/if}}
          <div class="cstore-admin-missions">{{#each this.missions as |mission|}}<article><span>{{mission.icon}}</span><div><strong>{{mission.name}}</strong><p>{{mission.description}}</p><small>{{mission.metric}} · hedef {{mission.target}} · {{mission.claim_count}} kez alındı</small></div><b>+{{mission.reward}} {{this.settings.currency_symbol}}</b><i class={{if mission.enabled "is-on" "is-off"}}>{{if mission.enabled "Etkin" "Kapalı"}}</i><button type="button" {{on "click" (fn this.editMission mission)}}>Düzenle</button><button class="is-danger" type="button" {{on "click" (fn this.deleteMission mission)}}>{{if mission.claim_count "Kapat" "Sil"}}</button></article>{{else}}<p>Henüz görev yok.</p>{{/each}}</div>
        </section>
      {{else if (eq this.activeTab "payments")}}
        <CosmeticsStorePaymentsAdmin @packages={{this.args.model.orb_packages}} @providers={{this.args.model.payment_providers}} @payments={{this.args.model.payments}} />
      {{else}}
        <section class="cstore-admin__section cstore-admin-wallets">
          <div class="cstore-admin__section-heading"><div><h2>Kullanıcı cüzdanları</h2><p>Her manuel işlem değiştirilemez işlem defterine, yapan yöneticiyle birlikte kaydedilir.</p></div></div>
          <form class="cstore-wallet-search" {{on "submit" this.findWallet}}><label>Kullanıcı adı<input value={{this.walletUsername}} {{on "input" this.updateWalletUsername}} placeholder="kullanici" /></label><button class="btn btn-primary" type="submit">Cüzdanı getir</button></form>
          {{#if this.walletResult}}
            <div class="cstore-wallet-card"><header><img src={{this.walletResult.user.avatar_url}} alt="" /><div><strong>{{this.walletResult.user.name}}</strong><span>@{{this.walletResult.user.username}}</span></div><b>{{this.settings.currency_symbol}} {{this.walletResult.wallet.balance}}</b></header><div class="cstore-wallet-card__stats"><span><strong>{{this.walletResult.wallet.lifetime_earned}}</strong><small>Toplam kazanılan</small></span><span><strong>{{this.walletResult.wallet.lifetime_spent}}</strong><small>Toplam harcanan</small></span></div><form {{on "submit" this.adjustWallet}}><label>Miktar<input type="number" value={{this.walletAmount}} {{on "input" this.updateWalletAmount}} placeholder="+100 veya -100" /></label><label>Neden<input maxlength="500" value={{this.walletReason}} {{on "input" this.updateWalletReason}} placeholder="İşlem açıklaması" /></label><button class="btn btn-primary" type="submit">Bakiyeyi güncelle</button></form><section><h3>Son hareketler</h3>{{#each this.walletResult.wallet.ledger as |entry|}}<article><span class={{if entry.credit "is-credit" "is-debit"}}>{{entry.amount}}</span><div><strong>{{entry.reason}}</strong><small>{{entry.entry_type}} · bakiye {{entry.balance_after}}</small></div></article>{{else}}<p>Henüz işlem yok.</p>{{/each}}</section></div>
          {{/if}}
        </section>
      {{/if}}
    </div>
  </template>
}
