import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import {
  activeProductFilterCount,
  filterAndSortProducts,
} from "../lib/cosmetics-store-product-filter";
import CosmeticsStoreDialog from "./cosmetics-store-dialog";
import CosmeticsStoreProductCard from "./cosmetics-store-product-card";

export default class CosmeticsStoreFavoritesPage extends Component {
  @service router;

  @tracked products = this.args.model?.products ?? [];
  @tracked wallet = this.args.model?.wallet ?? { balance: 0, debt: 0 };
  @tracked selectedProduct = null;
  @tracked busyProductId = null;
  @tracked busyGiftProductId = null;
  @tracked giftProductId = null;
  @tracked search = "";
  @tracked selectedKind = "";
  @tracked selectedRarity = "";
  @tracked selectedAvailability = "";
  @tracked selectedTag = "";
  @tracked productType = "";
  @tracked sortBy = "popular";
  @tracked onlyAffordable = false;
  @tracked onlyOwned = false;
  @tracked filtersOpen = false;

  get viewer() {
    return this.args.model?.viewer ?? {};
  }

  get settings() {
    return this.args.model?.settings ?? {};
  }

  get filters() {
    return this.args.model?.filters ?? {
      kinds: [],
      rarities: [],
      availability: [],
      tags: [],
    };
  }

  get previewUser() {
    return this.viewer.preview_user ?? {};
  }

  get rawFavoriteCount() {
    return this.products.filter((product) => product.favorite).length;
  }

  get filterState() {
    return {
      favoriteOnly: true,
      search: this.search,
      kind: this.selectedKind,
      rarity: this.selectedRarity,
      availability: this.selectedAvailability,
      tag: this.selectedTag,
      productType: this.productType,
      onlyAffordable: this.onlyAffordable,
      onlyOwned: this.onlyOwned,
      balance: this.wallet.balance,
      sortBy: this.sortBy,
    };
  }

  get favoriteProducts() {
    return filterAndSortProducts(this.products, this.filterState);
  }

  get activeFilterCount() {
    return activeProductFilterCount(this.filterState);
  }

  get hasActiveFilters() {
    return this.activeFilterCount > 0;
  }

  get resetDisabled() {
    return !this.hasActiveFilters;
  }

  get favoriteCountLabel() {
    return i18n("discourse_cosmetics_store.favorites_filters.saved_count", {
      count: this.rawFavoriteCount,
    });
  }

  get resultCountLabel() {
    return i18n("discourse_cosmetics_store.favorites_filters.result_count", {
      count: this.favoriteProducts.length,
    });
  }

  get activeFilterLabel() {
    return i18n("discourse_cosmetics_store.favorites_filters.active_filter_count", {
      count: this.activeFilterCount,
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
  navigate(routeName) {
    this.filtersOpen = false;
    this.router.transitionTo(routeName);
  }

  @action
  openProduct(product) {
    this.selectedProduct = product;
    this.giftProductId = null;
  }

  @action
  openGift(product) {
    if (!this.viewer.logged_in) {
      window.location.assign("/login?return_path=%2Fstore%2Ffavorites");
      return;
    }

    this.selectedProduct = product;
    this.giftProductId = product.giftable ? product.id : null;
  }

  @action
  closeProduct() {
    this.selectedProduct = null;
    this.giftProductId = null;
  }

  @action
  async toggleFavorite(product) {
    if (!this.viewer.logged_in) {
      window.location.assign("/login?return_path=%2Fstore%2Ffavorites");
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
  async purchase(product) {
    if (this.busyProductId || !product.purchasable) {
      return;
    }

    this.busyProductId = product.id;
    try {
      const response = await ajax(`/cosmetics-store/products/${product.id}/purchase.json`, {
        type: "POST",
      });
      this.wallet = {
        ...this.wallet,
        balance: response.balance,
        debt: response.debt,
      };
      this.replaceProduct(product.id, {
        purchased: true,
        owned: true,
        purchasable: false,
        purchase_count: Number(product.purchase_count || 0) + 1,
        popularity_score: Number(product.popularity_score || 0) + 10,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyProductId = null;
    }
  }

  @action
  async gift(product, username) {
    if (this.busyGiftProductId || !product.giftable) {
      return;
    }

    this.busyGiftProductId = product.id;
    try {
      const response = await ajax(`/cosmetics-store/products/${product.id}/gift.json`, {
        type: "POST",
        data: { username },
      });
      this.wallet = {
        ...this.wallet,
        balance: response.balance,
        debt: response.debt,
      };
      this.replaceProduct(product.id, {
        purchase_count: Number(product.purchase_count || 0) + 1,
        popularity_score: Number(product.popularity_score || 0) + 10,
      });
      this.closeProduct();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyGiftProductId = null;
    }
  }

  @action
  updateSearch(event) {
    this.search = event.target.value;
  }

  @action
  updateKind(event) {
    this.selectedKind = event.target.value;
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
    this.productType = event.target.value;
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
  toggleFilters() {
    this.filtersOpen = !this.filtersOpen;
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
  }

  <template>
    <div class="cstore-shell cstore-favorites-center">
      <header class="cstore-nav">
        <button
          class="cstore-nav__brand"
          type="button"
          {{on "click" (fn this.navigate "cosmetics-store")}}
        >
          <span>◈</span><strong>{{i18n "discourse_cosmetics_store.title"}}</strong>
        </button>

        <nav aria-label={{i18n "discourse_cosmetics_store.favorites_filters.store_sections"}}>
          <button type="button" {{on "click" (fn this.navigate "cosmetics-store")}}>
            {{i18n "discourse_cosmetics_store.favorites_filters.featured"}}
          </button>
          <button type="button" {{on "click" (fn this.navigate "cosmetics-store-browse")}}>
            {{i18n "discourse_cosmetics_store.favorites_filters.browse"}}
          </button>
          <button type="button" {{on "click" (fn this.navigate "cosmetics-store-collections")}}>
            {{i18n "discourse_cosmetics_store.favorites_filters.collections"}}
          </button>
          <button type="button" {{on "click" (fn this.navigate "cosmetics-store-orbs")}}>
            {{i18n "discourse_cosmetics_store.favorites_filters.orbs"}}
          </button>
          <button class="is-active" type="button">
            {{i18n "discourse_cosmetics_store.favorites_filters.favorites"}}
          </button>
        </nav>

        <div class="cstore-nav__tools">
          <button
            class="cstore-balance"
            type="button"
            {{on "click" (fn this.navigate "cosmetics-store-orbs")}}
          >
            {{this.settings.currency_symbol}} {{this.wallet.balance}}
          </button>
        </div>
      </header>

      <main class="cstore-section cstore-favorites-page">
        {{#unless this.viewer.logged_in}}
          <div class="cstore-empty">
            <strong>{{i18n "discourse_cosmetics_store.favorites_filters.login_title"}}</strong>
            <p>{{i18n "discourse_cosmetics_store.favorites_filters.login_description"}}</p>
            <a class="btn btn-primary" href="/login?return_path=%2Fstore%2Ffavorites">
              {{i18n "discourse_cosmetics_store.favorites_filters.login_action"}}
            </a>
          </div>
        {{else if (eq this.rawFavoriteCount 0)}}
          <div class="cstore-empty">
            <strong>{{i18n "discourse_cosmetics_store.favorites_filters.empty_title"}}</strong>
            <p>{{i18n "discourse_cosmetics_store.favorites_filters.empty_description"}}</p>
            <button type="button" {{on "click" (fn this.navigate "cosmetics-store-browse")}}>
              {{i18n "discourse_cosmetics_store.favorites_filters.browse_action"}}
            </button>
          </div>
        {{else}}
          <div class="cstore-browse-layout">
            <aside
              class="cstore-filters {{if this.filtersOpen 'is-open'}}"
              aria-label={{i18n "discourse_cosmetics_store.favorites_filters.filter_label"}}
            >
              <button
                class="cstore-filter-toggle"
                type="button"
                data-testid="favorites-filter-toggle"
                aria-expanded={{this.filtersOpen}}
                aria-controls="cstore-favorites-filter-body"
                {{on "click" this.toggleFilters}}
              >
                <span>
                  <strong>{{i18n "discourse_cosmetics_store.favorites_filters.filter_label"}}</strong>
                  {{#if this.hasActiveFilters}}<small>{{this.activeFilterLabel}}</small>{{/if}}
                </span>
                <span class="cstore-filter-toggle__chevron" aria-hidden="true">⌄</span>
              </button>

              <div id="cstore-favorites-filter-body" class="cstore-filters__body">
                <div class="cstore-section__heading">
                  <div>
                    <p class="cstore-eyebrow">{{i18n "discourse_cosmetics_store.favorites_filters.eyebrow"}}</p>
                    <h1>{{i18n "discourse_cosmetics_store.favorites_filters.title"}}</h1>
                    <span>{{this.favoriteCountLabel}}</span>
                  </div>
                </div>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.search"}}
                  <input
                    type="search"
                    value={{this.search}}
                    placeholder={{i18n "discourse_cosmetics_store.favorites_filters.search_placeholder"}}
                    {{on "input" this.updateSearch}}
                  />
                </label>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.product_type"}}
                  <select value={{this.productType}} {{on "change" this.updateProductType}}>
                    <option value="">{{i18n "discourse_cosmetics_store.favorites_filters.all"}}</option>
                    <option value="item">{{i18n "discourse_cosmetics_store.favorites_filters.single"}}</option>
                    <option value="bundle">{{i18n "discourse_cosmetics_store.favorites_filters.bundle"}}</option>
                  </select>
                </label>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.kind"}}
                  <select value={{this.selectedKind}} {{on "change" this.updateKind}}>
                    <option value="">{{i18n "discourse_cosmetics_store.favorites_filters.all"}}</option>
                    {{#each this.filters.kinds as |kind|}}
                      <option value={{kind.value}}>{{kind.label}} ({{kind.count}})</option>
                    {{/each}}
                  </select>
                </label>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.rarity"}}
                  <select value={{this.selectedRarity}} {{on "change" this.updateRarity}}>
                    <option value="">{{i18n "discourse_cosmetics_store.favorites_filters.all"}}</option>
                    {{#each this.filters.rarities as |rarity|}}
                      <option value={{rarity.value}}>{{rarity.label}} ({{rarity.count}})</option>
                    {{/each}}
                  </select>
                </label>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.availability"}}
                  <select value={{this.selectedAvailability}} {{on "change" this.updateAvailability}}>
                    <option value="">{{i18n "discourse_cosmetics_store.favorites_filters.all"}}</option>
                    {{#each this.filters.availability as |availability|}}
                      <option value={{availability.value}}>{{availability.label}} ({{availability.count}})</option>
                    {{/each}}
                  </select>
                </label>

                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.tag"}}
                  <select value={{this.selectedTag}} {{on "change" this.updateTag}}>
                    <option value="">{{i18n "discourse_cosmetics_store.favorites_filters.all"}}</option>
                    {{#each this.filters.tags as |tag|}}
                      <option value={{tag.value}}>#{{tag.label}} ({{tag.count}})</option>
                    {{/each}}
                  </select>
                </label>

                <label class="cstore-check">
                  <input type="checkbox" checked={{this.onlyAffordable}} {{on "change" this.toggleAffordable}} />
                  <span>{{i18n "discourse_cosmetics_store.favorites_filters.affordable"}}</span>
                </label>
                <label class="cstore-check">
                  <input type="checkbox" checked={{this.onlyOwned}} {{on "change" this.toggleOwned}} />
                  <span>{{i18n "discourse_cosmetics_store.favorites_filters.owned"}}</span>
                </label>

                {{#if this.hasActiveFilters}}
                  <span class="cstore-favorites-center__active-count">{{this.activeFilterLabel}}</span>
                {{/if}}
                <button
                  class="cstore-filter-reset"
                  type="button"
                  disabled={{this.resetDisabled}}
                  {{on "click" this.resetFilters}}
                >
                  {{i18n "discourse_cosmetics_store.favorites_filters.reset"}}
                </button>
              </div>
            </aside>

            <section class="cstore-results">
              <div class="cstore-results__bar">
                <div>
                  <p class="cstore-eyebrow">{{i18n "discourse_cosmetics_store.favorites_filters.results_eyebrow"}}</p>
                  <h1>{{i18n "discourse_cosmetics_store.favorites_filters.results_title"}}</h1>
                  <span>{{this.resultCountLabel}}</span>
                </div>
                <label>
                  {{i18n "discourse_cosmetics_store.favorites_filters.sort"}}
                  <select value={{this.sortBy}} {{on "change" this.updateSort}}>
                    <option value="popular">{{i18n "discourse_cosmetics_store.favorites_filters.sort_popular"}}</option>
                    <option value="newest">{{i18n "discourse_cosmetics_store.favorites_filters.sort_newest"}}</option>
                    <option value="price-low">{{i18n "discourse_cosmetics_store.favorites_filters.sort_price_low"}}</option>
                    <option value="price-high">{{i18n "discourse_cosmetics_store.favorites_filters.sort_price_high"}}</option>
                    <option value="name">{{i18n "discourse_cosmetics_store.favorites_filters.sort_name"}}</option>
                  </select>
                </label>
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
                  <strong>{{i18n "discourse_cosmetics_store.favorites_filters.no_matches_title"}}</strong>
                  <p>{{i18n "discourse_cosmetics_store.favorites_filters.no_matches_description"}}</p>
                  <button type="button" {{on "click" this.resetFilters}}>
                    {{i18n "discourse_cosmetics_store.favorites_filters.reset"}}
                  </button>
                </div>
              {{/if}}
            </section>
          </div>
        {{/unless}}
      </main>

      {{#if this.selectedProduct}}
        <CosmeticsStoreDialog
          @product={{this.selectedProduct}}
          @viewer={{this.viewer}}
          @settings={{this.settings}}
          @balance={{this.wallet.balance}}
          @busy={{eq this.busyProductId this.selectedProduct.id}}
          @giftBusy={{eq this.busyGiftProductId this.selectedProduct.id}}
          @startGift={{eq this.giftProductId this.selectedProduct.id}}
          @onPurchase={{this.purchase}}
          @onGift={{this.gift}}
          @onClose={{this.closeProduct}}
        />
      {{/if}}
    </div>
  </template>
}
