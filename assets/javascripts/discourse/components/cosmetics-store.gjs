import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import dCloseOnClickOutside from "discourse/ui-kit/modifiers/d-close-on-click-outside";
import CosmeticsStoreDialog from "./cosmetics-store-dialog";
import CosmeticsStorePreview from "./cosmetics-store-preview";
import CosmeticsStoreProductCard from "./cosmetics-store-product-card";
import CosmeticsStoreOrbPurchases from "./cosmetics-store-orb-purchases";

const KIND_FOR_ROUTE = {
  "avatar-frames": "avatar_frame",
  nameplates: "nameplate",
  "card-decorations": "card_decoration",
  "profile-effects": "profile_effect",
};

const PRODUCT_TYPE_FOR_ROUTE = {
  bundles: "bundle",
  items: "item",
};

const ROUTE_FOR_PRODUCT_TYPE = {
  bundle: "bundles",
  item: "items",
};

export default class CosmeticsStore extends Component {
  @service router;

  @tracked products = this.args.model?.products ?? [];
  @tracked missions = this.args.model?.missions ?? [];
  @tracked wallet = this.args.model?.wallet ?? {
    balance: 0,
    debt: 0,
    lifetime_earned: 0,
    lifetime_spent: 0,
    ledger: [],
  };
  @tracked selectedProduct = null;
  @tracked busyProductId = null;
  @tracked busyMissionId = null;
  @tracked busyGiftProductId = null;
  @tracked giftProductId = null;
  @tracked notice = null;
  @tracked search = "";
  @tracked selectedKind = "";
  @tracked selectedRarity = "";
  @tracked selectedTag = "";
  @tracked productType = "";
  @tracked sortBy = "popular";
  @tracked onlyAffordable = false;
  @tracked onlyOwned = false;
  @tracked browseMenuOpen = false;

  get settings() {
    return this.args.model?.settings ?? {};
  }

  get activeTab() {
    return this.args.model?.route_tab ?? "featured";
  }

  get effectiveSelectedKind() {
    return KIND_FOR_ROUTE[this.args.model?.route_filter] ?? this.selectedKind;
  }

  get effectiveProductType() {
    return PRODUCT_TYPE_FOR_ROUTE[this.args.model?.route_filter] ?? this.productType;
  }

  get viewer() {
    return this.args.model?.viewer ?? {};
  }

  get previewUser() {
    return this.viewer.preview_user ?? {};
  }

  get filters() {
    return this.args.model?.filters ?? { kinds: [], rarities: [], tags: [] };
  }

  get sectionIds() {
    return this.args.model?.sections ?? {};
  }

  get heroProduct() {
    return this.editorPicks[0] || this.featuredProducts[0] || this.products[0];
  }

  get editorPicks() {
    return this.productsFor(this.sectionIds.editor_picks);
  }

  get featuredProducts() {
    return this.productsFor(this.sectionIds.featured);
  }

  get popularProducts() {
    return this.productsFor(this.sectionIds.popular);
  }

  get bundleProducts() {
    return this.uniqueProducts([
      ...this.productsFor(this.sectionIds.bundles),
      ...this.products.filter((product) => product.product_type === "bundle"),
    ]).slice(0, 12);
  }

  get newestProducts() {
    return this.productsFor(this.sectionIds.newest);
  }

  get profileEffectProducts() {
    return this.productsFor(this.sectionIds.profile_effects);
  }

  get orbPackages() {
    return this.args.model?.orb_packages ?? [];
  }

  get paymentProviders() {
    return this.args.model?.payment_providers ?? [];
  }

  get payments() {
    return this.args.model?.payments ?? [];
  }

  get favoriteProducts() {
    return this.products.filter((product) => product.favorite);
  }

  get collections() {
    return this.args.model?.collections ?? [];
  }

  get activeCollection() {
    const slug = this.args.model?.collection_slug;
    return this.collections.find((collection) => collection.slug === slug);
  }

  get collectionProducts() {
    return this.productsFor(this.activeCollection?.product_ids || []);
  }

  get featuredCards() {
    const heroId = this.heroProduct?.id;
    const picks = [...this.editorPicks, ...this.featuredProducts, ...this.profileEffectProducts, ...this.popularProducts];
    return this.uniqueProducts(picks).filter((product) => product.id !== heroId).slice(0, 8);
  }

  get browseProducts() {
    const query = this.search.trim().toLocaleLowerCase("tr-TR");
    let rows = this.products.filter((product) => {
      if (query) {
        const searchable = [
          product.name,
          product.description,
          ...(product.tags || []),
          ...(product.items || []).map((item) => item.name),
        ]
          .join(" ")
          .toLocaleLowerCase("tr-TR");
        if (!searchable.includes(query)) {
          return false;
        }
      }
      if (
        this.effectiveSelectedKind &&
        !(product.kinds || []).includes(this.effectiveSelectedKind)
      ) {
        return false;
      }
      if (this.selectedRarity && product.rarity_label !== this.selectedRarity) {
        return false;
      }
      if (this.selectedTag && !(product.tags || []).includes(this.selectedTag)) {
        return false;
      }
      if (this.effectiveProductType && product.product_type !== this.effectiveProductType) {
        return false;
      }
      if (this.onlyAffordable && product.price > this.wallet.balance) {
        return false;
      }
      if (this.onlyOwned && !product.owned) {
        return false;
      }
      return true;
    });

    rows = [...rows];
    if (this.sortBy === "price-low") {
      rows.sort((a, b) => a.price - b.price || a.name.localeCompare(b.name));
    } else if (this.sortBy === "price-high") {
      rows.sort((a, b) => b.price - a.price || a.name.localeCompare(b.name));
    } else if (this.sortBy === "newest") {
      rows.sort((a, b) => String(b.created_at).localeCompare(String(a.created_at)));
    } else if (this.sortBy === "name") {
      rows.sort((a, b) => a.name.localeCompare(b.name, "tr"));
    } else {
      rows.sort((a, b) => b.popularity_score - a.popularity_score || a.sort_order - b.sort_order);
    }
    return rows;
  }

  productsFor(ids = []) {
    const wanted = new Map(this.products.map((product) => [product.id, product]));
    return (ids || []).map((id) => wanted.get(id)).filter(Boolean);
  }

  uniqueProducts(rows) {
    const seen = new Set();
    return rows.filter((product) => {
      if (seen.has(product.id)) {
        return false;
      }
      seen.add(product.id);
      return true;
    });
  }

  replaceProduct(productId, attributes) {
    let replacement;
    this.products = this.products.map((product) => {
      if (product.id !== productId) {
        return product;
      }
      replacement = { ...product, ...attributes };
      return replacement;
    });
    if (this.selectedProduct?.id === productId) {
      this.selectedProduct = replacement;
    }
  }

  @action
  navigateTo(tab, value) {
    this.notice = null;
    this.browseMenuOpen = false;
    const routeValue = typeof value === "string" ? value.trim() : "";
    const routes = {
      featured: "cosmetics-store",
      browse: "cosmetics-store-browse",
      orbs: "cosmetics-store-orbs",
      favorites: "cosmetics-store-favorites",
      collections: "cosmetics-store-collections",
    };

    if (tab === "browse" && routeValue) {
      this.router.transitionTo("cosmetics-store-browse-category", routeValue);
    } else if (tab === "collection" && routeValue) {
      this.router.transitionTo("cosmetics-store-collection", routeValue);
    } else {
      this.router.transitionTo(routes[tab] || routes.featured);
    }
  }

  @action
  toggleBrowseMenu() {
    this.browseMenuOpen = !this.browseMenuOpen;
  }

  @action
  closeBrowseMenu() {
    this.browseMenuOpen = false;
  }

  @action
  openProduct(product) {
    this.selectedProduct = product;
    this.giftProductId = null;
    this.notice = null;
  }

  @action
  openGift(product) {
    if (!this.viewer.logged_in) {
      window.location.assign("/login?return_path=%2Fstore%2Fbrowse");
      return;
    }
    this.selectedProduct = product;
    this.giftProductId = product.id;
    this.notice = null;
  }

  @action
  closeProduct() {
    this.selectedProduct = null;
    this.giftProductId = null;
  }

  @action
  async gift(product, username) {
    if (this.busyGiftProductId) {
      return;
    }
    this.busyGiftProductId = product.id;
    this.notice = null;
    try {
      const response = await ajax(`/cosmetics-store/products/${product.id}/gift.json`, {
        type: "POST",
        data: { username },
      });
      this.wallet = { ...this.wallet, balance: response.balance, debt: response.debt };
      this.replaceProduct(product.id, {
        purchase_count: product.purchase_count + 1,
        popularity_score: product.popularity_score + 10,
      });
      this.notice = response.message;
      this.closeProduct();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyGiftProductId = null;
    }
  }

  @action
  async purchase(product) {
    if (this.busyProductId) {
      return;
    }
    this.busyProductId = product.id;
    this.notice = null;
    try {
      const response = await ajax(`/cosmetics-store/products/${product.id}/purchase.json`, {
        type: "POST",
      });
      this.wallet = { ...this.wallet, balance: response.balance, debt: response.debt };
      this.replaceProduct(product.id, {
        purchased: true,
        owned: true,
        purchasable: false,
        purchase_count: product.purchase_count + 1,
        popularity_score: product.popularity_score + 10,
      });
      this.notice = response.message;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyProductId = null;
    }
  }

  @action
  async toggleFavorite(product) {
    if (!this.viewer.logged_in) {
      window.location.assign("/login?return_path=%2Fstore");
      return;
    }
    try {
      await ajax(`/cosmetics-store/products/${product.id}/favorite.json`, {
        type: product.favorite ? "DELETE" : "PUT",
      });
      this.replaceProduct(product.id, { favorite: !product.favorite });
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async claimMission(mission) {
    if (this.busyMissionId || !mission.complete || mission.claimed) {
      return;
    }
    this.busyMissionId = mission.id;
    try {
      const response = await ajax(`/cosmetics-store/missions/${mission.id}/claim.json`, {
        type: "POST",
      });
      this.wallet = { ...this.wallet, balance: response.balance, debt: response.debt };
      this.missions = this.missions.map((row) =>
        row.id === mission.id ? { ...row, claimed: true } : row
      );
      this.notice = response.message;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyMissionId = null;
    }
  }

  @action
  updateSearch(event) {
    this.search = event.target.value;
  }

  @action
  openSearch() {
    if (this.activeTab !== "browse") {
      this.navigateTo("browse");
    }
  }

  @action
  updateKind(event) {
    const kind = event.target.value;
    const category = Object.keys(KIND_FOR_ROUTE).find((key) => KIND_FOR_ROUTE[key] === kind);
    this.selectedKind = category ? "" : kind;
    this.navigateTo("browse", category);
  }

  @action
  updateRarity(event) {
    this.selectedRarity = event.target.value;
  }

  @action
  updateTag(event) {
    this.selectedTag = event.target.value;
  }

  @action
  updateProductType(event) {
    const productType = event.target.value;
    const category = ROUTE_FOR_PRODUCT_TYPE[productType];
    this.productType = category ? "" : productType;
    this.navigateTo("browse", category);
  }

  @action
  updateSort(event) {
    this.sortBy = event.target.value;
  }

  @action
  toggleAffordable(event) {
    this.onlyAffordable = event.target.checked;
  }

  @action
  toggleOwned(event) {
    this.onlyOwned = event.target.checked;
  }

  @action
  resetFilters() {
    this.search = "";
    this.selectedKind = "";
    this.selectedRarity = "";
    this.selectedTag = "";
    this.productType = "";
    this.sortBy = "popular";
    this.onlyAffordable = false;
    this.onlyOwned = false;
    if (this.args.model?.route_filter) {
      this.navigateTo("browse");
    }
  }

  <template>
    <div class="cstore-shell">
      <header class="cstore-nav">
        <button class="cstore-nav__brand" type="button" {{on "click" (fn this.navigateTo "featured")}}>
          <span>◈</span><strong>Kozmetik Mağazası</strong>
        </button>
        <nav aria-label="Mağaza bölümleri">
          <button class={{if (eq this.activeTab "featured") "is-active"}} type="button" {{on "click" (fn this.navigateTo "featured")}}>Öne Çıkanlar</button>
          <div class="cstore-nav__browse-menu {{if this.browseMenuOpen 'is-open'}}" {{dCloseOnClickOutside this.closeBrowseMenu}}>
            <button class={{if (eq this.activeTab "browse") "is-active"}} type="button" aria-haspopup="true" aria-expanded={{this.browseMenuOpen}} {{on "click" this.toggleBrowseMenu}}>Göz At <span>⌄</span></button>
            <div class="cstore-nav__dropdown" role="menu">
              <button type="button" {{on "click" (fn this.navigateTo "browse")}}>Tümüne göz at</button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "avatar-frames")}}>Avatar çerçeveleri</button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "nameplates")}}>İsim plakaları</button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "card-decorations")}}>Kart dekorasyonları</button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "profile-effects")}}>Profil efektleri</button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "bundles")}}>Paketler</button>
              <span></span>
              <button type="button" {{on "click" (fn this.navigateTo "collections")}}>Koleksiyonlar</button>
            </div>
          </div>
          <button class={{if (eq this.activeTab "collections") "is-active"}} type="button" {{on "click" (fn this.navigateTo "collections")}}>Koleksiyonlar</button>
          <button class={{if (eq this.activeTab "orbs") "is-active"}} type="button" {{on "click" (fn this.navigateTo "orbs")}}>Orbs Özel</button>
          {{#if this.viewer.logged_in}}
            <button class={{if (eq this.activeTab "favorites") "is-active"}} type="button" {{on "click" (fn this.navigateTo "favorites")}}>Favoriler</button>
          {{/if}}
        </nav>
        <div class="cstore-nav__tools">
          <label><span aria-hidden="true">⌕</span><input value={{this.search}} {{on "focus" this.openSearch}} {{on "input" this.updateSearch}} placeholder="Mağazada ara" /></label>
          <button class="cstore-balance" type="button" {{on "click" (fn this.navigateTo "orbs")}}>
            <span>{{this.settings.currency_symbol}}</span><strong>{{this.wallet.balance}}</strong>
          </button>
        </div>
      </header>

      {{#if this.notice}}<div class="cstore-notice" role="status">✓ {{this.notice}}</div>{{/if}}

      {{#if (eq this.activeTab "featured")}}
        <main class="cstore-featured">
          {{#if this.heroProduct as |hero|}}
            <section class="cstore-hero">
              {{#if hero.hero_image_url}}<img class="cstore-hero__art" src={{hero.hero_image_url}} alt="" />{{/if}}
              <div class="cstore-hero__shade"></div>
              <div class="cstore-hero__copy">
                <p class="cstore-eyebrow">SENİN.ME KOLEKSİYONU</p>
                <h1>{{this.settings.hero_title}}</h1>
                <p>{{this.settings.hero_subtitle}}</p>
                <button type="button" {{on "click" (fn this.navigateTo "collections")}}>Koleksiyonları keşfet →</button>
              </div>
              <div class="cstore-hero__preview"><CosmeticsStorePreview @product={{hero}} @previewUser={{this.previewUser}} /></div>
            </section>
          {{else}}
            <section class="cstore-empty"><strong>Mağaza hazırlanıyor</strong><p>Yönetim panelinden ilk ürünü eklediğinde burada görünecek.</p></section>
          {{/if}}

          {{#if this.featuredCards.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading"><div><p class="cstore-eyebrow">VİTRİN</p><h2>{{this.settings.editor_title}}</h2></div><button type="button" {{on "click" (fn this.navigateTo "browse")}}>Tümünü gör →</button></div>
              <div class="cstore-grid cstore-grid--featured">
                {{#each this.featuredCards as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.bundleProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading"><div><p class="cstore-eyebrow">BİRLİKTE DAHA İYİ</p><h2>Kozmetik paketleri</h2></div></div>
              <div class="cstore-grid cstore-grid--wide">
                {{#each this.bundleProducts as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.profileEffectProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading"><div><p class="cstore-eyebrow">PROFİL ATMOSFERİ</p><h2>Profil efektleri</h2></div><button type="button" {{on "click" (fn this.navigateTo "browse" "profile-effects")}}>Tümünü gör →</button></div>
              <div class="cstore-grid">
                {{#each this.profileEffectProducts as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.popularProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading"><div><p class="cstore-eyebrow">TOPLULUĞUN TARZI</p><h2>En çok kullanılanlar</h2></div></div>
              <div class="cstore-grid">
                {{#each this.popularProducts as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            </section>
          {{/if}}
        </main>
      {{else if (eq this.activeTab "browse")}}
        <main class="cstore-browse">
          <aside class="cstore-filters">
            <div><p class="cstore-eyebrow">KATALOG</p><h2>Detaylı filtreler</h2></div>
            <label>Arama<input value={{this.search}} {{on "input" this.updateSearch}} placeholder="Ürün, etiket veya tür" /></label>
            <label>Ürün türü<select value={{this.effectiveProductType}} {{on "change" this.updateProductType}}><option value="">Tümü</option><option value="item">Tekli kozmetik</option><option value="bundle">Paket</option></select></label>
            <label>Kozmetik türü<select value={{this.effectiveSelectedKind}} {{on "change" this.updateKind}}><option value="">Tümü</option>{{#each this.filters.kinds as |kind|}}<option value={{kind.value}}>{{kind.label}} ({{kind.count}})</option>{{/each}}</select></label>
            <label>Nadirlik<select value={{this.selectedRarity}} {{on "change" this.updateRarity}}><option value="">Tümü</option>{{#each this.filters.rarities as |rarity|}}<option value={{rarity.value}}>{{rarity.label}} ({{rarity.count}})</option>{{/each}}</select></label>
            <label>Etiket<select value={{this.selectedTag}} {{on "change" this.updateTag}}><option value="">Tümü</option>{{#each this.filters.tags as |tag|}}<option value={{tag.value}}>#{{tag.label}} ({{tag.count}})</option>{{/each}}</select></label>
            <label class="cstore-check"><input type="checkbox" checked={{this.onlyAffordable}} {{on "change" this.toggleAffordable}} /><span>Sadece bakiyeme uygun</span></label>
            <label class="cstore-check"><input type="checkbox" checked={{this.onlyOwned}} {{on "change" this.toggleOwned}} /><span>Sadece koleksiyonum</span></label>
            <button class="cstore-filter-reset" type="button" {{on "click" this.resetFilters}}>Filtreleri temizle</button>
          </aside>
          <section class="cstore-results">
            <div class="cstore-results__bar"><div><p class="cstore-eyebrow">GÖZ AT</p><h1>Tüm kozmetikler</h1><span>{{this.browseProducts.length}} sonuç</span></div><label>Sırala<select value={{this.sortBy}} {{on "change" this.updateSort}}><option value="popular">En popüler</option><option value="newest">En yeni</option><option value="price-low">Fiyat: düşükten yükseğe</option><option value="price-high">Fiyat: yüksekten düşüğe</option><option value="name">Ada göre</option></select></label></div>
            {{#if this.browseProducts.length}}
              <div class="cstore-grid">
                {{#each this.browseProducts as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            {{else}}
              <div class="cstore-empty"><strong>Eşleşen ürün bulunamadı</strong><p>Filtrelerden birini değiştir veya temizle.</p></div>
            {{/if}}
          </section>
        </main>
      {{else if (eq this.activeTab "orbs")}}
        <main class="cstore-orbs">
          <section class="cstore-orbs__hero"><div><p class="cstore-eyebrow">TOPLULUK ÖDÜLLERİ</p><h1>Katıl, katkı sağla, Orbs kazan.</h1><p>Görevlerin ilerlemesi sunucuda doğrulanır. Kazandığın Orbs yalnızca bu mağazada kullanılır.</p>{{#if this.wallet.debt}}<div class="cstore-refund-debt" role="status"><strong>{{this.wallet.debt}} {{this.settings.currency_symbol}} iade borcu</strong><span>İade edilen satın alımdan harcanmış bakiye kaldı. Yeni Orb kazançların önce bu tutarı kapatır.</span></div>{{/if}}</div><div class="cstore-orb-balance"><span>{{this.settings.currency_symbol}}</span><strong>{{this.wallet.balance}}</strong><small>mevcut {{this.settings.currency_name}}</small>{{#if this.wallet.debt}}<small class="is-debt">−{{this.wallet.debt}} iade borcu</small>{{/if}}<a class="cstore-orb-balance__topup" href="#orb-yukle">+ Orb Yükle</a></div></section>
          <CosmeticsStoreOrbPurchases @packages={{this.orbPackages}} @providers={{this.paymentProviders}} @payments={{this.payments}} @settings={{this.settings}} @viewer={{this.viewer}} />
          {{#if this.viewer.logged_in}}
            <section class="cstore-mission-layout">
              <div>
                <div class="cstore-section__heading"><div><p class="cstore-eyebrow">GÖREVLER</p><h2>Orbs kazan</h2></div></div>
                <div class="cstore-missions">
                  {{#each this.missions as |mission|}}
                    <article class="cstore-mission {{if mission.claimed 'is-claimed'}}">
                      <span class="cstore-mission__icon">{{mission.icon}}</span>
                      <div><strong>{{mission.name}}</strong><p>{{mission.description}}</p><progress class="cstore-progress" value={{mission.progress}} max={{mission.target}}></progress><small>{{mission.progress}} / {{mission.target}}</small></div>
                      <div class="cstore-mission__reward"><b>+{{mission.reward}} {{this.settings.currency_symbol}}</b><button type="button" disabled={{if mission.complete mission.claimed true}} {{on "click" (fn this.claimMission mission)}}>{{if mission.claimed "Alındı" (if mission.complete "Ödülü al" "Devam et")}}</button></div>
                    </article>
                  {{/each}}
                </div>
              </div>
              <aside class="cstore-ledger"><p class="cstore-eyebrow">CÜZDAN</p><h2>Son hareketler</h2><div class="cstore-wallet-stats"><span><strong>{{this.wallet.lifetime_earned}}</strong><small>Toplam kazanılan</small></span><span><strong>{{this.wallet.lifetime_spent}}</strong><small>Toplam harcanan</small></span>{{#if this.wallet.debt}}<span class="is-debt"><strong>{{this.wallet.debt}}</strong><small>İade borcu</small></span>{{/if}}</div>{{#each this.wallet.ledger as |entry|}}<article><span class={{if entry.credit "is-credit" "is-debit"}}>{{entry.amount}}</span><div><strong>{{entry.reason}}</strong><small>{{entry.entry_type}}{{#if entry.debt_after}} · borç {{entry.debt_after}}{{/if}}</small></div><b>{{entry.balance_after}}</b></article>{{else}}<p class="cstore-muted">Henüz cüzdan hareketi yok.</p>{{/each}}</aside>
            </section>
          {{else}}
            <section class="cstore-empty"><strong>Görevler için giriş yap</strong><p>İlerlemeni görmek, Orbs kazanmak ve satın almak için forum hesabınla giriş yap.</p><a href="/login?return_path=%2Fstore">Giriş yap</a></section>
          {{/if}}
        </main>
      {{else if (eq this.activeTab "collections")}}
        <main class="cstore-collections-page">
          {{#if this.activeCollection}}
            <section class="cstore-collection-hero">
              {{#if this.activeCollection.image_url}}<img src={{this.activeCollection.image_url}} alt="" />{{/if}}
              <div><button type="button" {{on "click" (fn this.navigateTo "collections")}}>Tüm koleksiyonlar /</button><p class="cstore-eyebrow">KOLEKSİYON</p><h1>{{this.activeCollection.name}}</h1><span>{{this.activeCollection.product_count}} ürün</span></div>
            </section>
            <section class="cstore-section">
              <div class="cstore-grid">
                {{#each this.collectionProducts as |product|}}
                  <CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />
                {{/each}}
              </div>
            </section>
          {{else}}
            <div class="cstore-section__heading"><div><p class="cstore-eyebrow">AYNI EVRENDEN</p><h1>Koleksiyonlar</h1><span>Aynı temayı paylaşan kozmetik paketlerini keşfet.</span></div></div>
            {{#if this.collections.length}}
              <div class="cstore-collections-grid">
                {{#each this.collections as |collection|}}
                  <button type="button" {{on "click" (fn this.navigateTo "collection" collection.slug)}}>
                    {{#if collection.image_url}}<img src={{collection.image_url}} alt="" loading="lazy" />{{/if}}
                    <span><small>KOLEKSİYON</small><strong>{{collection.name}}</strong><b>{{collection.product_count}} ürün →</b></span>
                  </button>
                {{/each}}
              </div>
            {{else}}
              <div class="cstore-empty"><strong>Henüz koleksiyon yok</strong><p>Yönetim panelinden ürünlere aynı koleksiyon adını vererek koleksiyon oluşturabilirsin.</p></div>
            {{/if}}
          {{/if}}
        </main>
      {{else}}
        <main class="cstore-section cstore-favorites-page">
          <div class="cstore-section__heading"><div><p class="cstore-eyebrow">KOLEKSİYON RADARI</p><h1>Favorilerin</h1></div></div>
          {{#if this.favoriteProducts.length}}
            <div class="cstore-grid">{{#each this.favoriteProducts as |product|}}<CosmeticsStoreProductCard @product={{product}} @previewUser={{this.previewUser}} @currencySymbol={{this.settings.currency_symbol}} @favoritesEnabled={{this.viewer.favorites_enabled}} @hoverPreview={{this.settings.hover_preview}} @onOpen={{this.openProduct}} @onGift={{this.openGift}} @onFavorite={{this.toggleFavorite}} />{{/each}}</div>
          {{else}}
            <div class="cstore-empty"><strong>Henüz favorin yok</strong><p>Beğendiğin ürünlerdeki kalbe dokun; burada saklayalım.</p><button type="button" {{on "click" (fn this.navigateTo "browse")}}>Mağazaya göz at</button></div>
          {{/if}}
        </main>
      {{/if}}

      {{#if this.selectedProduct}}
        <CosmeticsStoreDialog @product={{this.selectedProduct}} @settings={{this.settings}} @viewer={{this.viewer}} @balance={{this.wallet.balance}} @busy={{eq this.busyProductId this.selectedProduct.id}} @giftBusy={{eq this.busyGiftProductId this.selectedProduct.id}} @startGift={{eq this.giftProductId this.selectedProduct.id}} @onClose={{this.closeProduct}} @onPurchase={{this.purchase}} @onGift={{this.gift}} />
      {{/if}}
    </div>
  </template>
}
