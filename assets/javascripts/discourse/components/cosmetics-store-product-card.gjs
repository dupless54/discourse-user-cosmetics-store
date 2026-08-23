import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import CosmeticsStorePreview from "./cosmetics-store-preview";

export default class CosmeticsStoreProductCard extends Component {
  <template>
    <article class="cstore-product {{if @product.owned 'is-owned'}} {{if @hoverPreview 'has-hover-preview'}}">
      <button class="cstore-product__open" type="button" {{on "click" (fn @onOpen @product)}} aria-label="{{@product.name}} ayrıntılarını aç">
        <CosmeticsStorePreview @product={{@product}} />
        <span class="cstore-product__shade"></span>
        <span class="cstore-product__peek">Canlı önizleme</span>
      </button>

      {{#if @favoritesEnabled}}
        <button
          class="cstore-favorite {{if @product.favorite 'is-active'}}"
          type="button"
          aria-label={{if @product.favorite "Favoriden çıkar" "Favoriye ekle"}}
          aria-pressed={{@product.favorite}}
          {{on "click" (fn @onFavorite @product)}}
        >♥</button>
      {{/if}}

      <button class="cstore-product__info" type="button" {{on "click" (fn @onOpen @product)}}>
        <span class="cstore-product__meta">
          {{#if @product.rarity_label}}<i>{{@product.rarity_label}}</i>{{/if}}
          {{#if @product.editor_pick}}<i>EDİTÖR SEÇİMİ</i>{{/if}}
        </span>
        <strong>{{@product.name}}</strong>
        <small>{{if (eq @product.product_type "bundle") "Paket" "Kozmetik"}} · {{@product.item_count}} parça</small>
        <span class="cstore-product__price">
          {{#if @product.owned}}Koleksiyonda{{else}}{{@currencySymbol}} {{@product.price}}{{/if}}
        </span>
      </button>
    </article>
  </template>
}
