import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import Form from "discourse/components/form";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  availabilityBadge,
  availabilityDetail,
} from "../lib/cosmetics-store-availability";
import CosmeticsStoreUserCardPreview from "./cosmetics-store-user-card-preview";

const I18N_PREFIX = "discourse_cosmetics_store.dialog";

export default class CosmeticsStoreDialog extends Component {
  @tracked giftMode = this.args.startGift ?? false;

  giftFormData = { recipient: "" };

  get canAfford() {
    return Number(this.args.balance || 0) >= Number(this.args.product?.price || 0);
  }

  get availabilityBadge() {
    return availabilityBadge(this.args.product);
  }

  get availabilityDetail() {
    return availabilityDetail(this.args.product);
  }

  get purchaseDisabled() {
    return this.args.busy || !this.canAfford || !this.args.product?.purchasable;
  }

  get giftDisabled() {
    return this.args.giftBusy || !this.args.product?.giftable;
  }

  get productEyebrow() {
    return i18n(
      `${I18N_PREFIX}.${
        this.args.product?.product_type === "bundle"
          ? "bundle_eyebrow"
          : "cosmetic_eyebrow"
      }`
    );
  }

  get priceLabel() {
    return i18n(`${I18N_PREFIX}.price`);
  }

  get balanceLabel() {
    return i18n(`${I18N_PREFIX}.balance`);
  }

  get ownedLabel() {
    return i18n(`${I18N_PREFIX}.owned`);
  }

  get upcomingLabel() {
    return i18n(`${I18N_PREFIX}.upcoming_short`);
  }

  get loginToPurchaseLabel() {
    return i18n(`${I18N_PREFIX}.login_to_purchase`);
  }

  get giftLabel() {
    return i18n(`${I18N_PREFIX}.gift`);
  }

  get giftRecipientTitle() {
    return i18n(`${I18N_PREFIX}.gift_recipient_title`);
  }

  get giftHelpText() {
    return i18n(`${I18N_PREFIX}.gift_help`);
  }

  get giftPlaceholder() {
    return i18n(`${I18N_PREFIX}.gift_placeholder`);
  }

  get giftSubmitLabel() {
    return i18n(`${I18N_PREFIX}.${this.args.giftBusy ? "sending" : "send_gift"}`);
  }

  get previewEyebrow() {
    return i18n(`${I18N_PREFIX}.preview_eyebrow`);
  }

  get purchaseLabel() {
    if (this.args.busy) {
      return i18n(`${I18N_PREFIX}.processing`);
    }
    if (this.args.product?.sale_state === "upcoming") {
      return i18n(`${I18N_PREFIX}.upcoming`);
    }
    if (!this.canAfford) {
      return i18n(`${I18N_PREFIX}.insufficient_orbs`);
    }
    return i18n(`${I18N_PREFIX}.purchase`);
  }

  @action
  toggleGift() {
    if (this.giftDisabled) {
      return;
    }
    this.giftMode = !this.giftMode;
  }

  @action
  submitGift(data) {
    const username = String(data.recipient || "")
      .trim()
      .replace(/^@/, "");

    if (!username || this.giftDisabled) {
      return;
    }

    return this.args.onGift(this.args.product, username);
  }

  <template>
    <DModal
      @title={{@product.name}}
      @subtitle={{@product.description}}
      @closeModal={{@onClose}}
      @bodyClass="cstore-dialog__body"
      @inline={{@inline}}
      class="cstore-dialog --max"
    >
      <:body>
        <div class="cstore-dialog__window">
          <aside class="cstore-dialog__details">
            <p class="cstore-eyebrow">{{this.productEyebrow}}</p>

            <div class="cstore-dialog__badges">
              {{#if @product.rarity_label}}
                <span class="cstore-rarity-badge">{{@product.rarity_label}}</span>
              {{/if}}
              {{#if this.availabilityBadge}}
                <span class="cstore-product__availability-badge">
                  {{this.availabilityBadge}}
                </span>
              {{/if}}
            </div>

            {{#if this.availabilityDetail}}
              <p class="cstore-dialog__availability">
                {{dIcon "clock"}}
                {{this.availabilityDetail}}
              </p>
            {{/if}}

            <div class="cstore-dialog__items">
              {{#each @product.items as |item|}}
                <article>
                  {{#if item.image_url}}
                    <img src={{item.image_url}} alt="" loading="lazy" />
                  {{else}}
                    <span>{{dIcon "image"}}</span>
                  {{/if}}
                  <div>
                    <strong>{{item.name}}</strong>
                    <small>{{item.kind_label}}</small>
                  </div>
                </article>
              {{/each}}
            </div>

            <div class="cstore-dialog__purchase">
              <div>
                <small>{{this.priceLabel}}</small>
                <strong>{{@settings.currency_symbol}} {{@product.price}}</strong>
              </div>
              <div>
                <small>{{this.balanceLabel}}</small>
                <strong>{{@settings.currency_symbol}} {{@balance}}</strong>
              </div>

              {{#if @product.owned}}
                <span class="cstore-owned-label">
                  {{dIcon "check"}}
                  {{this.ownedLabel}}
                </span>
              {{else if @viewer.logged_in}}
                <DButton
                  @action={{fn @onPurchase @product}}
                  @disabled={{this.purchaseDisabled}}
                  @icon="cart-shopping"
                  @translatedLabel={{this.purchaseLabel}}
                  class="cstore-buy btn-primary"
                />
              {{else if (eq @product.sale_state "upcoming")}}
                <span class="cstore-owned-label">
                  {{dIcon "clock"}}
                  {{this.upcomingLabel}}
                </span>
              {{else}}
                <a class="cstore-buy btn btn-primary" href="/login?return_path=%2Fstore">
                  {{dIcon "right-to-bracket"}}
                  {{this.loginToPurchaseLabel}}
                </a>
              {{/if}}

              {{#if @viewer.logged_in}}
                <DButton
                  @action={{this.toggleGift}}
                  @disabled={{this.giftDisabled}}
                  @icon="gift"
                  @translatedLabel={{this.giftLabel}}
                  class="cstore-gift-toggle"
                />
              {{/if}}
            </div>

            {{#if this.giftMode}}
              <div class="cstore-gift-panel">
                <Form
                  @data={{this.giftFormData}}
                  @onSubmit={{this.submitGift}}
                  class="cstore-gift-formkit"
                  as |form|
                >
                  <form.Field
                    @name="recipient"
                    @title={{this.giftRecipientTitle}}
                    @type="input"
                    @validation="required:trim"
                    @disabled={{this.giftDisabled}}
                    @helpText={{this.giftHelpText}}
                    as |field|
                  >
                    <field.Control
                      autocomplete="off"
                      maxlength="60"
                      placeholder={{this.giftPlaceholder}}
                    />
                  </form.Field>

                  <form.Actions>
                    <form.Submit
                      @disabled={{this.giftDisabled}}
                      @translatedLabel={{this.giftSubmitLabel}}
                      class="btn-primary"
                    />
                  </form.Actions>
                </Form>
              </div>
            {{/if}}
          </aside>

          <main class="cstore-dialog__live">
            <p class="cstore-eyebrow">{{this.previewEyebrow}}</p>
            <CosmeticsStoreUserCardPreview
              @product={{@product}}
              @user={{@viewer.preview_user}}
            />
            {{#if @product.tags.length}}
              <div class="cstore-dialog__tags">
                {{#each @product.tags as |tag|}}
                  <span>#{{tag}}</span>
                {{/each}}
              </div>
            {{/if}}
          </main>
        </div>
      </:body>
    </DModal>
  </template>
}
