import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import {
  availabilityBadge,
  availabilityDetail,
} from "../lib/cosmetics-store-availability";
import CosmeticsStorePreview from "./cosmetics-store-preview";

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

  get primaryActionLabel() {
    return this.args.product?.sale_state === "upcoming" ? "Yakında" : "Satın al";
  }

  <template>
    <article class="cstore-product {{if @product.owned 'is-owned'}} {{if (eq @product.sale_state 'upcoming') 'is-upcoming'}} {{if @hoverPreview 'has-hover-preview'}}">
      <button class="cstore-product__open" type="button" {{on "click" (fn @onOpen @product)}} aria-label="{{@product.name}} ayrıntılarını aç">
        <CosmeticsStorePreview @product={{@product}} @previewUser={{@previewUser}} />
        <span class="cstore-product__shade"></span>
        <span class="cstore-product__peek">{{dIcon "eye"}} Canlı önizleme</span>
        {{#if this.availabilityBadge}}
          <span class="cstore-product__availability-badge">{{this.availabilityBadge}}</span>
        {{/if}}
      </button>

      {{#if @favoritesEnabled}}
        <button
          class="cstore-favorite {{if @product.favorite 'is-active'}}"
          type="button"
          aria-label={{if @product.favorite "Favoriden çıkar" "Favoriye ekle"}}
          aria-pressed={{@product.favorite}}
          disabled={{this.favoriteDisabled}}
          {{on "click" (fn @onFavorite @product)}}
        >{{dIcon "heart"}}</button>
      {{/if}}

      <div class="cstore-product__actions">
        {{#unless @product.owned}}
          <button class="cstore-product__buy" type="button" {{on "click" (fn @onOpen @product)}}>
            <span>{{@currencySymbol}} {{@product.price}}</span><b>{{dIcon "cart-shopping"}} {{this.primaryActionLabel}}</b>
          </button>
        {{/unless}}
        <button class="cstore-product__gift" type="button" disabled={{not @product.giftable}} aria-label="{{@product.name}} ürününü hediye et" {{on "click" (fn @onGift @product)}}>{{dIcon "gift"}}</button>
      </div>

      <button class="cstore-product__info" type="button" {{on "click" (fn @onOpen @product)}}>
        <span class="cstore-product__meta">
          {{#if @product.rarity_label}}<i class="cstore-rarity-badge">{{@product.rarity_label}}</i>{{/if}}
          {{#if @product.editor_pick}}<i>EDİTÖR SEÇİMİ</i>{{/if}}
        </span>
        <strong>{{@product.name}}</strong>
        <small>{{if (eq @product.product_type "bundle") "Paket" "Kozmetik"}} · {{@product.item_count}} parça</small>
        {{#if this.availabilityDetail}}<small class="cstore-product__availability-detail">{{dIcon "clock"}} {{this.availabilityDetail}}</small>{{/if}}
        <span class="cstore-product__price">
          {{#if @product.owned}}<span class="cstore-owned-inline">{{dIcon "check"}} Koleksiyonunda</span>{{else}}{{@currencySymbol}} {{@product.price}}{{/if}}
        </span>
      </button>
    </article>
  </template>
}
