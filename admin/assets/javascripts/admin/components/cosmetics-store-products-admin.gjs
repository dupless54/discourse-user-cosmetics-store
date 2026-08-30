import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";

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
  collection_name: "",
  collection_slug: "",
  collection_image_url: "",
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

export default class CosmeticsStoreProductsAdmin extends Component {
  @tracked products = this.args.model?.products ?? [];
  @tracked editingProduct = null;
  @tracked saving = false;
  @tracked status = null;

  get cosmeticItems() {
    return this.args.model?.cosmetic_items ?? [];
  }

  get settings() {
    return this.args.model?.settings ?? {
      currency_name: "Orbs",
      currency_symbol: "◈",
    };
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
        .map((item) => ({
          ...item,
          selected: selected.has(item.id),
          disabled: !item.enabled,
        })),
    }));
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
    let value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;
    if (["price", "sort_order"].includes(field)) {
      value = Number.parseInt(value || "0", 10);
    }

    const next = { ...this.editingProduct, [field]: value };
    if (
      field === "product_type" &&
      value === "item" &&
      next.cosmetic_item_ids.length > 1
    ) {
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
    this.editingProduct = {
      ...this.editingProduct,
      cosmetic_item_ids: [...ids],
    };
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
    if (
      !window.confirm(`“${product.name}” ürününü silmek istediğine emin misin?`)
    ) {
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

  <template>
    <section class="cstore-admin cstore-admin__section cstore-admin-products">
      <div class="cstore-admin__section-heading">
        <div>
          <h2>Mağaza ürünleri</h2>
          <p>Tek bir kozmetiği veya birden fazla öğeyi paket halinde yayınla.</p>
        </div>
        <button class="btn btn-primary" type="button" {{on "click" this.newProduct}}>
          + Yeni ürün
        </button>
      </div>

      {{#if this.status}}
        <div class="cstore-admin__status" role="status">✓ {{this.status}}</div>
      {{/if}}

      {{#if this.editingProduct}}
        <form class="cstore-admin-form" {{on "submit" this.saveProduct}}>
          <div class="cstore-admin-form__title">
            <div>
              <h3>{{if this.editingProduct.id "Ürünü düzenle" "Yeni ürün"}}</h3>
              <p>Ürün exclusive ise, mağazadan alınana kadar kozmetik seçicide kilitli kalır.</p>
            </div>
            <button type="button" {{on "click" this.cancelProduct}}>×</button>
          </div>
          <div class="cstore-admin-form__grid">
            <label>Ürün adı<input required maxlength="120" value={{this.editingProduct.name}} {{on "input" (fn this.updateProduct "name")}} /></label>
            <label>Slug<input maxlength="140" value={{this.editingProduct.slug}} {{on "input" (fn this.updateProduct "slug")}} placeholder="Boşsa otomatik oluşur" /></label>
            <label>Ürün türü<select value={{this.editingProduct.product_type}} {{on "change" (fn this.updateProduct "product_type")}}><option value="item">Tekli kozmetik</option><option value="bundle">Paket</option></select></label>
            <label>Orbs fiyatı<input required min="0" type="number" value={{this.editingProduct.price}} {{on "input" (fn this.updateProduct "price")}} /></label>
            <label>Nadirlik etiketi<input maxlength="40" value={{this.editingProduct.rarity_label}} {{on "input" (fn this.updateProduct "rarity_label")}} placeholder="Efsanevi" /></label>
            <label>Nadirlik rengi<input type="color" value={{this.editingProduct.rarity_color}} {{on "input" (fn this.updateProduct "rarity_color")}} /></label>
            <label>Sıra<input min="0" type="number" value={{this.editingProduct.sort_order}} {{on "input" (fn this.updateProduct "sort_order")}} /></label>
            <label>Etiketler<input value={{this.editingProduct.tags_csv}} {{on "input" (fn this.updateProduct "tags_csv")}} placeholder="anime, neon, oyun" /></label>
            <label>Koleksiyon adı<input maxlength="120" value={{this.editingProduct.collection_name}} {{on "input" (fn this.updateProduct "collection_name")}} placeholder="Örn. Cehennem" /></label>
            <label>Koleksiyon slug<input maxlength="140" value={{this.editingProduct.collection_slug}} {{on "input" (fn this.updateProduct "collection_slug")}} placeholder="Boşsa koleksiyon adından oluşur" /></label>
            <label class="is-wide">Koleksiyon kapak görseli URL<input type="url" value={{this.editingProduct.collection_image_url}} {{on "input" (fn this.updateProduct "collection_image_url")}} /></label>
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
          <fieldset class="cstore-admin-items">
            <legend>Paketteki kozmetikler</legend>
            <p>{{if (eq this.editingProduct.product_type "item") "Tam olarak bir öğe seç." "En az iki öğe seç."}}</p>
            {{#each this.groupedCosmeticItems as |group|}}
              <section>
                <h4>{{group.label}}</h4>
                <div>
                  {{#each group.items as |item|}}
                    <label class={{if item.enabled "" "is-disabled-item"}}>
                      <input type={{if (eq this.editingProduct.product_type "item") "radio" "checkbox"}} name={{if (eq this.editingProduct.product_type "item") "cosmetic-item" "cosmetic-items"}} checked={{item.selected}} disabled={{item.disabled}} {{on "change" (fn this.toggleCosmetic item)}} />
                      <span>{{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{else}}<i>✦</i>{{/if}}<b>{{item.name}}</b><small>{{item.rarity_label}}</small></span>
                    </label>
                  {{/each}}
                </div>
              </section>
            {{/each}}
          </fieldset>
          <div class="cstore-admin-form__actions">
            <button class="btn" type="button" {{on "click" this.cancelProduct}}>İptal</button>
            <button class="btn btn-primary" type="submit" disabled={{this.saving}}>{{if this.saving "Kaydediliyor…" "Ürünü kaydet"}}</button>
          </div>
        </form>
      {{/if}}

      <div class="cstore-admin-table-wrap">
        <table class="cstore-admin-table d-table">
          <thead class="d-table__header"><tr><th>Ürün</th><th>Tür</th><th>İçerik</th><th>Fiyat</th><th>Vitrin</th><th>Satış</th><th>İşlemler</th></tr></thead>
          <tbody class="d-table__body">
            {{#each this.products as |product|}}
              <tr class="d-table__row">
                <td class="d-table__cell --overview"><strong>{{product.name}}</strong><small>/{{product.slug}}</small></td>
                <td class="d-table__cell --detail"><div class="d-table__mobile-label">Tür</div>{{if (eq product.product_type "bundle") "Paket" "Tekli"}}</td>
                <td class="d-table__cell --detail"><div class="d-table__mobile-label">İçerik</div>{{product.item_names.length}} öğe</td>
                <td class="d-table__cell --detail"><div class="d-table__mobile-label">Fiyat</div>{{this.settings.currency_symbol}} {{product.price}}</td>
                <td class="d-table__cell --detail"><div class="d-table__mobile-label">Vitrin</div><span class={{if product.enabled "is-on" "is-off"}}>{{if product.enabled "Yayında" "Kapalı"}}</span>{{#if product.editor_pick}} <span>Editör</span>{{/if}}</td>
                <td class="d-table__cell --detail"><div class="d-table__mobile-label">Satış</div>{{product.purchase_count}}</td>
                <td class="d-table__cell --controls"><div class="d-table__cell-actions"><button class="btn btn-text btn-small" type="button" {{on "click" (fn this.editProduct product)}}>Düzenle</button><button class="btn btn-danger btn-small" type="button" {{on "click" (fn this.deleteProduct product)}}>Sil</button></div></td>
              </tr>
            {{else}}
              <tr class="d-table__row"><td class="d-table__cell" colspan="7">Henüz mağaza ürünü yok.</td></tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </section>
  </template>
}
