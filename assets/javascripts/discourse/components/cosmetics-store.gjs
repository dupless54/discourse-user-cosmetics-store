import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import dCloseOnClickOutside from "discourse/ui-kit/modifiers/d-close-on-click-outside";
import I18n, { i18n } from "discourse-i18n";
import { availabilityMatches } from "../lib/cosmetics-store-availability";
import CosmeticsStoreDialog from "./cosmetics-store-dialog";
import CosmeticsStoreOrbPurchases from "./cosmetics-store-orb-purchases";
import CosmeticsStorePreview from "./cosmetics-store-preview";
import CosmeticsStoreProductCard from "./cosmetics-store-product-card";

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
  @tracked selectedAvailability = "";
  @tracked selectedTag = "";
  @tracked productType = "";
  @tracked sortBy = "popular";
  @tracked onlyAffordable = false;
  @tracked onlyOwned = false;
  @tracked browseMenuOpen = false;
  @tracked filtersOpen = false;

  get settings() {
    return this.args.model?.settings ?? {};
  }

  get activeTab() {
    return this.args.model?.route_tab ?? "featured";
  }

  get currentLocale() {
    return I18n.currentBcp47Locale;
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
    return this.args.model?.filters ?? {
      kinds: [],
      rarities: [],
      availability: [],
      tags: [],
    };
  }

  get sectionIds() {
    return this.args.model?.sections ?? {};
  }

  get activeProducts() {
    return this.products.filter((product) => product.sale_state === "active");
  }

  get heroProduct() {
    return this.editorPicks[0] || this.featuredProducts[0] || this.activeProducts[0];
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
      ...this.activeProducts.filter((product) => product.product_type === "bundle"),
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
    const picks = [
      ...this.editorPicks,
      ...this.featuredProducts,
      ...this.profileEffectProducts,
      ...this.popularProducts,
    ];
    return this.uniqueProducts(picks)
      .filter((product) => product.id !== heroId)
      .slice(0, 8);
  }

  get browseProducts() {
    const query = this.search.trim().toLocaleLowerCase(this.currentLocale);
    let rows = this.products.filter((product) => {
      if (query) {
        const searchable = [
          product.name,
          product.description,
          ...(product.tags || []),
          ...(product.items || []).map((item) => item.name),
        ]
          .join(" ")
          .toLocaleLowerCase(this.currentLocale);
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
      if (
        this.selectedAvailability &&
        !availabilityMatches(product, this.selectedAvailability)
      ) {
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
      rows.sort(
        (a, b) =>
          a.price - b.price || a.name.localeCompare(b.name, this.currentLocale)
      );
    } else if (this.sortBy === "price-high") {
      rows.sort(
        (a, b) =>
          b.price - a.price || a.name.localeCompare(b.name, this.currentLocale)
      );
    } else if (this.sortBy === "newest") {
      rows.sort((a, b) => String(b.created_at).localeCompare(String(a.created_at)));
    } else if (this.sortBy === "name") {
      rows.sort((a, b) => a.name.localeCompare(b.name, this.currentLocale));
    } else {
      rows.sort(
        (a, b) =>
          b.popularity_score - a.popularity_score || a.sort_order - b.sort_order
      );
    }
    return rows;
  }

  get activeFilterCount() {
    return [
      this.search.trim(),
      this.effectiveSelectedKind,
      this.selectedRarity,
      this.selectedAvailability,
      this.selectedTag,
      this.effectiveProductType,
      this.onlyAffordable,
      this.onlyOwned,
    ].filter(Boolean).length;
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
    this.filtersOpen = false;
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
  toggleFilters() {
    this.filtersOpen = !this.filtersOpen;
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
    if (!product.giftable) {
      this.openProduct(product);
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
    if (this.busyGiftProductId || !product.giftable) {
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
    if (this.busyProductId || !product.purchasable) {
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
    if (!product.favorite && !product.favoriteable) {
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
    const category = Object.keys(KIND_FOR_ROUTE).find(
      (key) => KIND_FOR_ROUTE[key] === kind
    );
    this.selectedKind = category ? "" : kind;
    this.navigateTo("browse", category);
  }

  @action
  updateRarity(event) {
    this.selectedRarity = event.target.value;
  }

  @action
  updateAvailability(event) {
    this.selectedAvailability = event.target.value;
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
    this.selectedAvailability = "";
    this.selectedTag = "";
    this.productType = "";
    this.sortBy = "popular";
    this.onlyAffordable = false;
    this.onlyOwned = false;
    this.filtersOpen = false;
    if (this.args.model?.route_filter) {
      this.navigateTo("browse");
    }
  }

  <template>
    <div class="cstore-shell">
      <header class="cstore-nav">
        <button
          class="cstore-nav__brand"
          type="button"
          {{on "click" (fn this.navigateTo "featured")}}
        >
          <span>◈</span><strong>{{i18n "discourse_cosmetics_store.title"}}</strong>
        </button>
        <nav aria-label={{i18n "discourse_cosmetics_store.storefront.nav.sections_label"}}>
          <button
            class={{if (eq this.activeTab "featured") "is-active"}}
            type="button"
            {{on "click" (fn this.navigateTo "featured")}}
          >{{i18n "discourse_cosmetics_store.storefront.nav.featured"}}</button>
          <div
            class="cstore-nav__browse-menu {{if this.browseMenuOpen 'is-open'}}"
            {{dCloseOnClickOutside this.closeBrowseMenu}}
          >
            <button
              class={{if (eq this.activeTab "browse") "is-active"}}
              type="button"
              aria-haspopup="true"
              aria-expanded={{this.browseMenuOpen}}
              {{on "click" this.toggleBrowseMenu}}
            >
              {{i18n "discourse_cosmetics_store.storefront.nav.browse"}}
              <span>⌄</span>
            </button>
            <div class="cstore-nav__dropdown" role="menu">
              <button type="button" {{on "click" (fn this.navigateTo "browse")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.browse_all"}}
              </button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "avatar-frames")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.avatar_frames"}}
              </button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "nameplates")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.nameplates"}}
              </button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "card-decorations")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.card_decorations"}}
              </button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "profile-effects")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.profile_effects"}}
              </button>
              <button type="button" {{on "click" (fn this.navigateTo "browse" "bundles")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.bundles"}}
              </button>
              <span></span>
              <button type="button" {{on "click" (fn this.navigateTo "collections")}}>
                {{i18n "discourse_cosmetics_store.storefront.nav.collections"}}
              </button>
            </div>
          </div>
          <button
            class={{if (eq this.activeTab "collections") "is-active"}}
            type="button"
            {{on "click" (fn this.navigateTo "collections")}}
          >{{i18n "discourse_cosmetics_store.storefront.nav.collections"}}</button>
          <button
            class={{if (eq this.activeTab "orbs") "is-active"}}
            type="button"
            {{on "click" (fn this.navigateTo "orbs")}}
          >{{i18n "discourse_cosmetics_store.storefront.nav.orbs"}}</button>
          {{#if this.viewer.logged_in}}
            <button
              class={{if (eq this.activeTab "favorites") "is-active"}}
              type="button"
              {{on "click" (fn this.navigateTo "favorites")}}
            >{{i18n "discourse_cosmetics_store.storefront.nav.favorites"}}</button>
          {{/if}}
        </nav>
        <div class="cstore-nav__tools">
          <label>
            <span aria-hidden="true">⌕</span>
            <input
              value={{this.search}}
              {{on "focus" this.openSearch}}
              {{on "input" this.updateSearch}}
              placeholder={{i18n "discourse_cosmetics_store.storefront.nav.search_placeholder"}}
            />
          </label>
          <button
            class="cstore-balance"
            type="button"
            {{on "click" (fn this.navigateTo "orbs")}}
          >
            <span>{{this.settings.currency_symbol}}</span><strong>{{this.wallet.balance}}</strong>
          </button>
        </div>
      </header>

      {{#if this.notice}}
        <div class="cstore-notice" role="status">✓ {{this.notice}}</div>
      {{/if}}

      {{#if (eq this.activeTab "featured")}}
        <main class="cstore-featured">
          {{#if this.heroProduct as |hero|}}
            <section class="cstore-hero">
              {{#if hero.hero_image_url}}
                <img class="cstore-hero__art" src={{hero.hero_image_url}} alt="" />
              {{/if}}
              <div class="cstore-hero__shade"></div>
              <div class="cstore-hero__copy">
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.featured.hero_eyebrow"}}
                </p>
                <h1>{{this.settings.hero_title}}</h1>
                <p>{{this.settings.hero_subtitle}}</p>
                <button type="button" {{on "click" (fn this.navigateTo "collections")}}>
                  {{i18n "discourse_cosmetics_store.storefront.featured.explore_collections"}}
                </button>
              </div>
              <div class="cstore-hero__preview">
                <CosmeticsStorePreview @product={{hero}} @previewUser={{this.previewUser}} />
              </div>
            </section>
          {{else}}
            <section class="cstore-empty">
              <strong>{{i18n "discourse_cosmetics_store.storefront.featured.preparing_title"}}</strong>
              <p>{{i18n "discourse_cosmetics_store.storefront.featured.preparing_description"}}</p>
            </section>
          {{/if}}

          {{#if this.featuredCards.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading">
                <div>
                  <p class="cstore-eyebrow">
                    {{i18n "discourse_cosmetics_store.storefront.featured.showcase_eyebrow"}}
                  </p>
                  <h2>{{this.settings.editor_title}}</h2>
                </div>
                <button type="button" {{on "click" (fn this.navigateTo "browse")}}>
                  {{i18n "discourse_cosmetics_store.storefront.featured.view_all"}}
                </button>
              </div>
              <div class="cstore-grid cstore-grid--featured">
                {{#each this.featuredCards as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.bundleProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading">
                <div>
                  <p class="cstore-eyebrow">
                    {{i18n "discourse_cosmetics_store.storefront.featured.bundles_eyebrow"}}
                  </p>
                  <h2>{{i18n "discourse_cosmetics_store.storefront.featured.bundles_title"}}</h2>
                </div>
              </div>
              <div class="cstore-grid cstore-grid--wide">
                {{#each this.bundleProducts as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.profileEffectProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading">
                <div>
                  <p class="cstore-eyebrow">
                    {{i18n "discourse_cosmetics_store.storefront.featured.profile_effects_eyebrow"}}
                  </p>
                  <h2>{{i18n "discourse_cosmetics_store.storefront.featured.profile_effects_title"}}</h2>
                </div>
                <button
                  type="button"
                  {{on "click" (fn this.navigateTo "browse" "profile-effects")}}
                >{{i18n "discourse_cosmetics_store.storefront.featured.view_all"}}</button>
              </div>
              <div class="cstore-grid">
                {{#each this.profileEffectProducts as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            </section>
          {{/if}}

          {{#if this.popularProducts.length}}
            <section class="cstore-section">
              <div class="cstore-section__heading">
                <div>
                  <p class="cstore-eyebrow">
                    {{i18n "discourse_cosmetics_store.storefront.featured.popular_eyebrow"}}
                  </p>
                  <h2>{{i18n "discourse_cosmetics_store.storefront.featured.popular_title"}}</h2>
                </div>
              </div>
              <div class="cstore-grid">
                {{#each this.popularProducts as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            </section>
          {{/if}}
        </main>
      {{else if (eq this.activeTab "browse")}}
        <main class="cstore-browse">
          <aside class="cstore-filters {{if this.filtersOpen 'is-open'}}">
            <button
              class="cstore-filter-toggle"
              type="button"
              data-testid="browse-filter-toggle"
              aria-expanded={{this.filtersOpen}}
              aria-controls="cstore-browse-filter-body"
              {{on "click" this.toggleFilters}}
            >
              <span>
                <strong>{{i18n "discourse_cosmetics_store.storefront.browse.filters"}}</strong>
                {{#if this.activeFilterCount}}
                  <small>{{i18n
                    "discourse_cosmetics_store.storefront.browse.active_filters"
                    count=this.activeFilterCount
                  }}</small>
                {{/if}}
              </span>
              <span class="cstore-filter-toggle__chevron" aria-hidden="true">⌄</span>
            </button>
            <div id="cstore-browse-filter-body" class="cstore-filters__body">
              <div>
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.browse.catalog_eyebrow"}}
                </p>
                <h2>{{i18n "discourse_cosmetics_store.storefront.browse.detailed_filters"}}</h2>
              </div>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.search"}}
                <input
                  value={{this.search}}
                  {{on "input" this.updateSearch}}
                  placeholder={{i18n "discourse_cosmetics_store.storefront.browse.search_placeholder"}}
                />
              </label>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.product_type"}}
                <select value={{this.effectiveProductType}} {{on "change" this.updateProductType}}>
                  <option value="">{{i18n "discourse_cosmetics_store.storefront.browse.all"}}</option>
                  <option value="item">{{i18n "discourse_cosmetics_store.storefront.browse.item"}}</option>
                  <option value="bundle">{{i18n "discourse_cosmetics_store.storefront.browse.bundle"}}</option>
                </select>
              </label>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.cosmetic_kind"}}
                <select value={{this.effectiveSelectedKind}} {{on "change" this.updateKind}}>
                  <option value="">{{i18n "discourse_cosmetics_store.storefront.browse.all"}}</option>
                  {{#each this.filters.kinds as |kind|}}
                    <option value={{kind.value}}>{{kind.label}} ({{kind.count}})</option>
                  {{/each}}
                </select>
              </label>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.rarity"}}
                <select value={{this.selectedRarity}} {{on "change" this.updateRarity}}>
                  <option value="">{{i18n "discourse_cosmetics_store.storefront.browse.all"}}</option>
                  {{#each this.filters.rarities as |rarity|}}
                    <option value={{rarity.value}}>{{rarity.label}} ({{rarity.count}})</option>
                  {{/each}}
                </select>
              </label>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.availability"}}
                <select value={{this.selectedAvailability}} {{on "change" this.updateAvailability}}>
                  <option value="">{{i18n "discourse_cosmetics_store.storefront.browse.all"}}</option>
                  {{#each this.filters.availability as |availability|}}
                    <option value={{availability.value}}>{{availability.label}} ({{availability.count}})</option>
                  {{/each}}
                </select>
              </label>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.tag"}}
                <select value={{this.selectedTag}} {{on "change" this.updateTag}}>
                  <option value="">{{i18n "discourse_cosmetics_store.storefront.browse.all"}}</option>
                  {{#each this.filters.tags as |tag|}}
                    <option value={{tag.value}}>#{{tag.label}} ({{tag.count}})</option>
                  {{/each}}
                </select>
              </label>
              <label class="cstore-check">
                <input
                  type="checkbox"
                  checked={{this.onlyAffordable}}
                  {{on "change" this.toggleAffordable}}
                />
                <span>{{i18n "discourse_cosmetics_store.storefront.browse.affordable_only"}}</span>
              </label>
              <label class="cstore-check">
                <input
                  type="checkbox"
                  checked={{this.onlyOwned}}
                  {{on "change" this.toggleOwned}}
                />
                <span>{{i18n "discourse_cosmetics_store.storefront.browse.owned_only"}}</span>
              </label>
              <button class="cstore-filter-reset" type="button" {{on "click" this.resetFilters}}>
                {{i18n "discourse_cosmetics_store.storefront.browse.reset"}}
              </button>
            </div>
          </aside>
          <section class="cstore-results">
            <div class="cstore-results__bar">
              <div>
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.browse.eyebrow"}}
                </p>
                <h1>{{i18n "discourse_cosmetics_store.storefront.browse.title"}}</h1>
                <span>{{i18n
                  "discourse_cosmetics_store.storefront.browse.result_count"
                  count=this.browseProducts.length
                }}</span>
              </div>
              <label>
                {{i18n "discourse_cosmetics_store.storefront.browse.sort"}}
                <select value={{this.sortBy}} {{on "change" this.updateSort}}>
                  <option value="popular">{{i18n "discourse_cosmetics_store.storefront.browse.sort_popular"}}</option>
                  <option value="newest">{{i18n "discourse_cosmetics_store.storefront.browse.sort_newest"}}</option>
                  <option value="price-low">{{i18n "discourse_cosmetics_store.storefront.browse.sort_price_low"}}</option>
                  <option value="price-high">{{i18n "discourse_cosmetics_store.storefront.browse.sort_price_high"}}</option>
                  <option value="name">{{i18n "discourse_cosmetics_store.storefront.browse.sort_name"}}</option>
                </select>
              </label>
            </div>
            {{#if this.browseProducts.length}}
              <div class="cstore-grid">
                {{#each this.browseProducts as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            {{else}}
              <div class="cstore-empty">
                <strong>{{i18n "discourse_cosmetics_store.storefront.browse.empty_title"}}</strong>
                <p>{{i18n "discourse_cosmetics_store.storefront.browse.empty_description"}}</p>
              </div>
            {{/if}}
          </section>
        </main>
      {{else if (eq this.activeTab "orbs")}}
        <main class="cstore-orbs">
          <section class="cstore-orbs__hero">
            <div>
              <p class="cstore-eyebrow">
                {{i18n "discourse_cosmetics_store.storefront.orbs.eyebrow"}}
              </p>
              <h1>{{i18n "discourse_cosmetics_store.storefront.orbs.title"}}</h1>
              <p>{{i18n "discourse_cosmetics_store.storefront.orbs.description"}}</p>
              {{#if this.wallet.debt}}
                <div class="cstore-refund-debt" role="status">
                  <strong>{{i18n
                    "discourse_cosmetics_store.storefront.orbs.refund_debt"
                    amount=this.wallet.debt
                    symbol=this.settings.currency_symbol
                  }}</strong>
                  <span>{{i18n "discourse_cosmetics_store.storefront.orbs.refund_debt_description"}}</span>
                </div>
              {{/if}}
            </div>
            <div class="cstore-orb-balance">
              <span>{{this.settings.currency_symbol}}</span>
              <strong>{{this.wallet.balance}}</strong>
              <small>{{i18n
                "discourse_cosmetics_store.storefront.orbs.current_balance"
                currency=this.settings.currency_name
              }}</small>
              {{#if this.wallet.debt}}
                <small class="is-debt">{{i18n
                  "discourse_cosmetics_store.storefront.orbs.debt_short"
                  amount=this.wallet.debt
                }}</small>
              {{/if}}
              <a class="cstore-orb-balance__topup" href="#orb-yukle">
                {{i18n "discourse_cosmetics_store.storefront.orbs.top_up"}}
              </a>
            </div>
          </section>
          <CosmeticsStoreOrbPurchases
            @packages={{this.orbPackages}}
            @providers={{this.paymentProviders}}
            @payments={{this.payments}}
            @settings={{this.settings}}
            @viewer={{this.viewer}}
          />
          {{#if this.viewer.logged_in}}
            <section class="cstore-mission-layout">
              <div>
                <div class="cstore-section__heading">
                  <div>
                    <p class="cstore-eyebrow">
                      {{i18n "discourse_cosmetics_store.storefront.orbs.missions_eyebrow"}}
                    </p>
                    <h2>{{i18n "discourse_cosmetics_store.storefront.orbs.earn_title"}}</h2>
                  </div>
                </div>
                <div class="cstore-missions">
                  {{#each this.missions as |mission|}}
                    <article class="cstore-mission {{if mission.claimed 'is-claimed'}}">
                      <span class="cstore-mission__icon">{{mission.icon}}</span>
                      <div>
                        <strong>{{mission.name}}</strong>
                        <p>{{mission.description}}</p>
                        <progress
                          class="cstore-progress"
                          value={{mission.progress}}
                          max={{mission.target}}
                        ></progress>
                        <small>{{mission.progress}} / {{mission.target}}</small>
                      </div>
                      <div class="cstore-mission__reward">
                        <b>+{{mission.reward}} {{this.settings.currency_symbol}}</b>
                        <button
                          type="button"
                          disabled={{if mission.complete mission.claimed true}}
                          {{on "click" (fn this.claimMission mission)}}
                        >
                          {{if
                            mission.claimed
                            (i18n "discourse_cosmetics_store.storefront.orbs.claimed")
                            (if
                              mission.complete
                              (i18n "discourse_cosmetics_store.storefront.orbs.claim")
                              (i18n "discourse_cosmetics_store.storefront.orbs.continue")
                            )
                          }}
                        </button>
                      </div>
                    </article>
                  {{/each}}
                </div>
              </div>
              <aside class="cstore-ledger">
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.orbs.wallet_eyebrow"}}
                </p>
                <h2>{{i18n "discourse_cosmetics_store.storefront.orbs.recent_activity"}}</h2>
                <div class="cstore-wallet-stats">
                  <span>
                    <strong>{{this.wallet.lifetime_earned}}</strong>
                    <small>{{i18n "discourse_cosmetics_store.storefront.orbs.lifetime_earned"}}</small>
                  </span>
                  <span>
                    <strong>{{this.wallet.lifetime_spent}}</strong>
                    <small>{{i18n "discourse_cosmetics_store.storefront.orbs.lifetime_spent"}}</small>
                  </span>
                  {{#if this.wallet.debt}}
                    <span class="is-debt">
                      <strong>{{this.wallet.debt}}</strong>
                      <small>{{i18n "discourse_cosmetics_store.storefront.orbs.refund_debt_label"}}</small>
                    </span>
                  {{/if}}
                </div>
                {{#each this.wallet.ledger as |entry|}}
                  <article>
                    <span class={{if entry.credit "is-credit" "is-debit"}}>{{entry.amount}}</span>
                    <div>
                      <strong>{{entry.reason}}</strong>
                      <small>
                        {{entry.entry_type}}
                        {{#if entry.debt_after}}
                          · {{i18n
                            "discourse_cosmetics_store.storefront.orbs.ledger_debt"
                            amount=entry.debt_after
                          }}
                        {{/if}}
                      </small>
                    </div>
                    <b>{{entry.balance_after}}</b>
                  </article>
                {{else}}
                  <p class="cstore-muted">
                    {{i18n "discourse_cosmetics_store.storefront.orbs.empty_ledger"}}
                  </p>
                {{/each}}
              </aside>
            </section>
          {{else}}
            <section class="cstore-empty">
              <strong>{{i18n "discourse_cosmetics_store.storefront.orbs.login_title"}}</strong>
              <p>{{i18n "discourse_cosmetics_store.storefront.orbs.login_description"}}</p>
              <a href="/login?return_path=%2Fstore">
                {{i18n "discourse_cosmetics_store.storefront.orbs.login_action"}}
              </a>
            </section>
          {{/if}}
        </main>
      {{else if (eq this.activeTab "collections")}}
        <main class="cstore-collections-page">
          {{#if this.activeCollection}}
            <section class="cstore-collection-hero">
              {{#if this.activeCollection.image_url}}
                <img src={{this.activeCollection.image_url}} alt="" />
              {{/if}}
              <div>
                <button type="button" {{on "click" (fn this.navigateTo "collections")}}>
                  {{i18n "discourse_cosmetics_store.storefront.collections.all_back"}}
                </button>
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.collections.eyebrow"}}
                </p>
                <h1>{{this.activeCollection.name}}</h1>
                <span>{{i18n
                  "discourse_cosmetics_store.storefront.collections.product_count"
                  count=this.activeCollection.product_count
                }}</span>
              </div>
            </section>
            <section class="cstore-section">
              <div class="cstore-grid">
                {{#each this.collectionProducts as |product|}}
                  <CosmeticsStoreProductCard
                    @product={{product}}
                    @previewUser={{this.previewUser}}
                    @currencySymbol={{this.settings.currency_symbol}}
                    @favoritesEnabled={{this.viewer.favorites_enabled}}
                    @hoverPreview={{this.settings.hover_preview}}
                    @onOpen={{this.openProduct}}
                    @onGift={{this.openGift}}
                    @onFavorite={{this.toggleFavorite}}
                  />
                {{/each}}
              </div>
            </section>
          {{else}}
            <div class="cstore-section__heading">
              <div>
                <p class="cstore-eyebrow">
                  {{i18n "discourse_cosmetics_store.storefront.collections.intro_eyebrow"}}
                </p>
                <h1>{{i18n "discourse_cosmetics_store.storefront.collections.title"}}</h1>
                <span>{{i18n "discourse_cosmetics_store.storefront.collections.intro_description"}}</span>
              </div>
            </div>
            {{#if this.collections.length}}
              <div class="cstore-collections-grid">
                {{#each this.collections as |collection|}}
                  <button
                    type="button"
                    {{on "click" (fn this.navigateTo "collection" collection.slug)}}
                  >
                    {{#if collection.image_url}}
                      <img src={{collection.image_url}} alt="" loading="lazy" />
                    {{/if}}
                    <span>
                      <small>{{i18n "discourse_cosmetics_store.storefront.collections.card_eyebrow"}}</small>
                      <strong>{{collection.name}}</strong>
                      <b>{{i18n
                        "discourse_cosmetics_store.storefront.collections.product_count"
                        count=collection.product_count
                      }} →</b>
                    </span>
                  </button>
                {{/each}}
              </div>
            {{else}}
              <div class="cstore-empty">
                <strong>{{i18n "discourse_cosmetics_store.storefront.collections.empty_title"}}</strong>
                <p>{{i18n "discourse_cosmetics_store.storefront.collections.empty_description"}}</p>
              </div>
            {{/if}}
          {{/if}}
        </main>
      {{else}}
        <main class="cstore-section cstore-favorites-page">
          <div class="cstore-section__heading">
            <div>
              <p class="cstore-eyebrow">
                {{i18n "discourse_cosmetics_store.storefront.favorites.eyebrow"}}
              </p>
              <h1>{{i18n "discourse_cosmetics_store.storefront.favorites.title"}}</h1>
            </div>
          </div>
          {{#if this.favoriteProducts.length}}
            <div class="cstore-grid">
              {{#each this.favoriteProducts as |product|}}
                <CosmeticsStoreProductCard
                  @product={{product}}
                  @previewUser={{this.previewUser}}
                  @currencySymbol={{this.settings.currency_symbol}}
                  @favoritesEnabled={{this.viewer.favorites_enabled}}
                  @hoverPreview={{this.settings.hover_preview}}
                  @onOpen={{this.openProduct}}
                  @onGift={{this.openGift}}
                  @onFavorite={{this.toggleFavorite}}
                />
              {{/each}}
            </div>
          {{else}}
            <div class="cstore-empty">
              <strong>{{i18n "discourse_cosmetics_store.storefront.favorites.empty_title"}}</strong>
              <p>{{i18n "discourse_cosmetics_store.storefront.favorites.empty_description"}}</p>
              <button type="button" {{on "click" (fn this.navigateTo "browse")}}>
                {{i18n "discourse_cosmetics_store.storefront.favorites.browse_action"}}
              </button>
            </div>
          {{/if}}
        </main>
      {{/if}}

      {{#if this.selectedProduct}}
        <CosmeticsStoreDialog
          @product={{this.selectedProduct}}
          @settings={{this.settings}}
          @viewer={{this.viewer}}
          @balance={{this.wallet.balance}}
          @busy={{eq this.busyProductId this.selectedProduct.id}}
          @giftBusy={{eq this.busyGiftProductId this.selectedProduct.id}}
          @startGift={{eq this.giftProductId this.selectedProduct.id}}
          @onClose={{this.closeProduct}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
        />
      {{/if}}
    </div>
  </template>
}
