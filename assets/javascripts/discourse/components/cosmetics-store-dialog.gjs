import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import CosmeticsStoreUserCardPreview from "./cosmetics-store-user-card-preview";

export default class CosmeticsStoreDialog extends Component {
  @tracked giftMode = this.args.startGift ?? false;
  @tracked recipientUsername = "";

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

  @action
  toggleGift() {
    this.giftMode = !this.giftMode;
  }

  @action
  updateRecipient(event) {
    this.recipientUsername = event.target.value;
  }

  @action
  submitGift(event) {
    event.preventDefault();
    const username = this.recipientUsername.trim().replace(/^@/, "");
    if (!username || this.args.giftBusy) {
      return;
    }
    this.args.onGift(this.args.product, username);
  }

  <template>
    <section class="cstore-dialog" role="dialog" aria-modal="true" aria-labelledby="cstore-dialog-title">
      <button class="cstore-dialog__backdrop" type="button" aria-label="Pencereyi kapat" {{on "click" @onClose}}></button>
      <div class="cstore-dialog__window">
        <button class="cstore-dialog__close" type="button" aria-label="Kapat" {{on "click" @onClose}}>{{dIcon "xmark"}}</button>

        <aside class="cstore-dialog__details">
          <p class="cstore-eyebrow">{{if (eq @product.product_type "bundle") "KOZMETİK PAKETİ" "ÖZEL KOZMETİK"}}</p>
          <h2 id="cstore-dialog-title">{{@product.name}}</h2>
          <p>{{@product.description}}</p>

          <div class="cstore-dialog__items">
            {{#each @product.items as |item|}}
              <article>
                {{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{else}}<span>{{dIcon "sparkles"}}</span>{{/if}}
                <div><strong>{{item.name}}</strong><small>{{item.kind_label}}</small></div>
              </article>
            {{/each}}
          </div>

          <div class="cstore-dialog__purchase">
            <div><small>Fiyat</small><strong>{{@settings.currency_symbol}} {{@product.price}}</strong></div>
            <div><small>Bakiyen</small><strong>{{@settings.currency_symbol}} {{@balance}}</strong></div>

            {{#if @product.owned}}
              <span class="cstore-owned-label">{{dIcon "check"}} Koleksiyonunda</span>
            {{else if @viewer.logged_in}}
              <button class="cstore-buy" type="button" disabled={{this.purchaseDisabled}} {{on "click" (fn @onPurchase @product)}}>
                {{dIcon "cart-shopping"}} {{this.purchaseLabel}}
              </button>
            {{else}}
              <a class="cstore-buy" href="/login?return_path=%2Fstore">{{dIcon "right-to-bracket"}} Satın almak için giriş yap</a>
            {{/if}}

            {{#if @viewer.logged_in}}
              <button class="cstore-gift-toggle" type="button" disabled={{@giftBusy}} {{on "click" this.toggleGift}}>{{dIcon "gift"}} Hediye et</button>
            {{/if}}
          </div>

          {{#if this.giftMode}}
            <form class="cstore-gift-form" {{on "submit" this.submitGift}}>
              <label for="cstore-gift-recipient">Hediye edilecek kullanıcı</label>
              <div><span>@</span><input id="cstore-gift-recipient" required autocomplete="off" maxlength="60" value={{this.recipientUsername}} {{on "input" this.updateRecipient}} placeholder="kullanıcı adı" /><button type="submit" disabled={{@giftBusy}}>{{dIcon "paper-plane"}} {{if @giftBusy "Gönderiliyor…" "Hediyeyi gönder"}}</button></div>
              <small>Fiyat ve alıcının sahiplik durumu sunucuda yeniden doğrulanır. Alıcı paketteki öğelerden birine sahipse işlem yapılmaz.</small>
            </form>
          {{/if}}
        </aside>

        <main class="cstore-dialog__live">
          <p class="cstore-eyebrow">PROFİLİNDE BÖYLE GÖRÜNÜR</p>
          <CosmeticsStoreUserCardPreview @product={{@product}} @user={{@viewer.preview_user}} />
          {{#if @product.tags.length}}
            <div class="cstore-dialog__tags">{{#each @product.tags as |tag|}}<span>#{{tag}}</span>{{/each}}</div>
          {{/if}}
        </main>
      </div>
    </section>
  </template>
}
