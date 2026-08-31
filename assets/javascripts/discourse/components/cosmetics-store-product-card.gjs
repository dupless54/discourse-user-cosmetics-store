import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  availabilityBadge,
  availabilityDetail,
} from "../lib/cosmetics-store-availability";
import CosmeticsStorePreview from "./cosmetics-store-preview";

const I18N_PREFIX = "discourse_cosmetics_store.product_card";

export default class CosmeticsStoreProductCard extends Component {
  get availabilityBadge() {
    return availabilityBadge(this.args.product);
  }

  get availabilityDetail() {
    return availabilityDetail(this.args.product);
  }

  get favoriteDisabled() {
    return !this.args.product?.favorite && !this.args.product?.favoriteable;
  }

  get giftDisabled() {
    return this.args.product?.sale_state !== "active";
  }

  get primaryActionLabel() {
    return i18n(
      `${I18N_PREFIX}.${
        this.args.product?.sale_state === "upcoming" ? "upcoming" : "purchase"
      }`
    );
  }

  get openDetailsLabel() {
    return i18n(`${I18N_PREFIX}.open_details`, {
      name: this.args.product?.name,
    });
  }

  get livePreviewLabel() {
    return i18n(`${I18N_PREFIX}.live_preview`);
  }

  get favoriteLabel() {
    return i18n(
      `${I18N_PREFIX}.${
        this.args.product?.favorite ? "remove_favorite" : "add_favorite"
      }`
    );
  }

  get giftLabel() {
    return i18n(`${I18N_PREFIX}.gift_product`, {
      name: this.args.product?.name,
    });
  }

  get editorPickLabel() {
    return i18n(`${I18N_PREFIX}.editor_pick`);
  }

  get productTypeLabel() {
    return i18n(
      `${I18N_PREFIX}.${
        this.args.product?.product_type === "bundle" ? "bundle" : "cosmetic"
      }`
    );
  }

  get itemCountLabel() {
    return i18n(`${I18N_PREFIX}.item_count`, {
      count: this.args.product?.item_count ?? 0,
    });
  }

  get ownedLabel() {
    return i18n(`${I18N_PREFIX}.owned`);
  }

  <template>
    <article class="cstore-product {{if @product.owned 'is-owned'}} {{if (eq @product.sale_state 'upcoming') 'is-upcoming'}} {{if @hoverPreview 'has-hover-preview'}}">
      <button class="cstore-product__open" type="button" {{on "click" (fn @onOpen @product)}} aria-label={{this.openDetailsLabel}}>
        <CosmeticsStorePreview @product={{@product}} @previewUser={{@previewUser}} />
        <span class="cstore-product__shade"></span>
        <span class="cstore-product__peek">{{dIcon "eye"}} {{this.livePreviewLabel}}</span>
        {{#if this.availabilityBadge}}
          <span class="cstore-product__availability-badge">{{this.availabilityBadge}}</span>
        {{/if}}
      </button>

      {{#if @favoritesEnabled}}
        <DButton
          class="cstore-favorite {{if @product.favorite 'is-active'}}"
          @icon="heart"
          @translatedAriaLabel={{this.favoriteLabel}}
          @ariaPressed={{@product.favorite}}
          @disabled={{this.favoriteDisabled}}
          @action={{@onFavorite}}
          @actionParam={{@product}}
        />
      {{/if}}

      <div class="cstore-product__actions">
        {{#unless @product.owned}}
          <button class="cstore-product__buy" type="button" {{on "click" (fn @onOpen @product)}}>
            <span>{{@currencySymbol}} {{@product.price}}</span><b>{{dIcon "cart-shopping"}} {{this.primaryActionLabel}}</b>
          </button>
        {{/unless}}
        <DButton
          class="cstore-product__gift"
          @icon="gift"
          @disabled={{this.giftDisabled}}
          @translatedAriaLabel={{this.giftLabel}}
          @action={{@onGift}}
          @actionParam={{@product}}
        />
      </div>

      <button class="cstore-product__info" type="button" {{on "click" (fn @onOpen @product)}}>
        <span class="cstore-product__meta">
          {{#if @product.rarity_label}}<i class="cstore-rarity-badge">{{@product.rarity_label}}</i>{{/if}}
          {{#if @product.editor_pick}}<i>{{this.editorPickLabel}}</i>{{/if}}
        </span>
        <strong>{{@product.name}}</strong>
        <small>{{this.productTypeLabel}} · {{this.itemCountLabel}}</small>
        {{#if this.availabilityDetail}}<small class="cstore-product__availability-detail">{{dIcon "clock"}} {{this.availabilityDetail}}</small>{{/if}}
        <span class="cstore-product__price">
          {{#if @product.owned}}<span class="cstore-owned-inline">{{dIcon "check"}} {{this.ownedLabel}}</span>{{else}}{{@currencySymbol}} {{@product.price}}{{/if}}
        </span>
      </button>
    </article>
  </template>
}
