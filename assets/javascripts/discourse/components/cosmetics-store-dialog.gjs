import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import CosmeticsStorePreview from "./cosmetics-store-preview";

export default class CosmeticsStoreDialog extends Component {
  get canAfford() {
    return Number(this.args.balance || 0) >= Number(this.args.product?.price || 0);
  }

  get purchaseDisabled() {
    return this.args.busy || !this.canAfford || !this.args.product?.purchasable;
  }

  get purchaseLabel() {
    if (this.args.busy) {
      return "İşleniyor…";
    }
    if (!this.canAfford) {
      return "Yetersiz Orbs";
    }
    return "Orbs ile satın al";
  }

  <template>
    <section class="cstore-dialog" role="dialog" aria-modal="true" aria-labelledby="cstore-dialog-title">
      <button class="cstore-dialog__backdrop" type="button" aria-label="Pencereyi kapat" {{on "click" @onClose}}></button>
      <div class="cstore-dialog__window">
        <button class="cstore-dialog__close" type="button" aria-label="Kapat" {{on "click" @onClose}}>×</button>

        <aside class="cstore-dialog__details">
          <p class="cstore-eyebrow">{{if (eq @product.product_type "bundle") "KOZMETİK PAKETİ" "ÖZEL KOZMETİK"}}</p>
          <h2 id="cstore-dialog-title">{{@product.name}}</h2>
          <p>{{@product.description}}</p>

          <div class="cstore-dialog__items">
            {{#each @product.items as |item|}}
              <article>
                {{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{else}}<span>✦</span>{{/if}}
                <div><strong>{{item.name}}</strong><small>{{item.kind_label}}</small></div>
              </article>
            {{/each}}
          </div>

          <div class="cstore-dialog__purchase">
            <div><small>Fiyat</small><strong>{{@settings.currency_symbol}} {{@product.price}}</strong></div>
            <div><small>Bakiyen</small><strong>{{@settings.currency_symbol}} {{@balance}}</strong></div>

            {{#if @product.owned}}
              <span class="cstore-owned-label">✓ Koleksiyonunda</span>
            {{else if @viewer.logged_in}}
              <button class="cstore-buy" type="button" disabled={{this.purchaseDisabled}} {{on "click" (fn @onPurchase @product)}}>
                {{this.purchaseLabel}}
              </button>
            {{else}}
              <a class="cstore-buy" href="/login?return_path=%2Fstore">Satın almak için giriş yap</a>
            {{/if}}
          </div>
        </aside>

        <main class="cstore-dialog__live">
          <p class="cstore-eyebrow">PROFİLİNDE BÖYLE GÖRÜNÜR</p>
          <div class="cstore-live-card">
            <CosmeticsStorePreview @product={{@product}} />
            <div class="cstore-live-card__identity"><i></i><strong>Topluluk üyesi</strong><span>@kullanici</span></div>
            <p>Tarzını toplulukta her yerde göster.</p>
          </div>
          {{#if @product.tags.length}}
            <div class="cstore-dialog__tags">{{#each @product.tags as |tag|}}<span>#{{tag}}</span>{{/each}}</div>
          {{/if}}
        </main>
      </div>
    </section>
  </template>
}
