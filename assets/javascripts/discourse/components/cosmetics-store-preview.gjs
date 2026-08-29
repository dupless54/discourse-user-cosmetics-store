import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { eq } from "discourse/truth-helpers";
import { prefersReducedMotion } from "../lib/cosmetics-store-motion";
import CosmeticsStoreProfileEffectLayers from "./cosmetics-store-profile-effect-layers";

const MOTION_HEAVY_KINDS = new Set(["card_decoration", "profile_effect"]);

export default class CosmeticsStorePreview extends Component {
  get previewUser() {
    return this.args.previewUser ?? {};
  }

  get previewName() {
    return (
      this.previewUser.name ||
      this.previewUser.username ||
      "Topluluk üyesi"
    );
  }

  get previewAvatarUrl() {
    return this.previewUser.avatar_url;
  }

  get previewItems() {
    const reduceMotion = prefersReducedMotion();

    return (this.args.product?.items || []).slice(0, 4).map((item) => ({
      ...item,
      hasEffectLayers: Array.isArray(item.layers) && item.layers.length > 0,
      showMotionAsset: !reduceMotion || !MOTION_HEAVY_KINDS.has(item.kind),
      visualStyle: htmlSafe(
        `--cstore-from:${item.gradient_from || "#5865f2"};` +
          `--cstore-to:${item.gradient_to || "#eb459e"};` +
          `--cstore-glow:${item.glow_color || "transparent"}`,
      ),
    }));
  }

  get isBundle() {
    return this.args.product?.product_type === "bundle";
  }

  <template>
    <div class="cstore-preview {{if this.isBundle 'cstore-preview--bundle' 'cstore-preview--single'}}">
      {{#if @product.preview_background_url}}
        <img class="cstore-preview__background" src={{@product.preview_background_url}} alt="" loading="lazy" />
      {{else if @product.card_image_url}}
        <img class="cstore-preview__background cstore-preview__background--card" src={{@product.card_image_url}} alt="" loading="lazy" />
      {{/if}}
      <div class="cstore-preview__surface">
        {{#each this.previewItems as |item|}}
          <div class="cstore-preview-item cstore-preview-item--{{item.kind}}" style={{item.visualStyle}} title={{item.name}}>
            {{#if (eq item.kind "avatar_frame")}}
              <span class="cstore-preview__avatar">
                {{#if this.previewAvatarUrl}}
                  <img class="cstore-preview__avatar-image" src={{this.previewAvatarUrl}} alt="" loading="eager" />
                {{else}}
                  <i></i>
                {{/if}}
              </span>
              {{#if item.image_url}}<img class="cstore-preview__frame" src={{item.image_url}} alt="" loading="lazy" />{{/if}}
            {{else if (eq item.kind "nameplate")}}
              <span class="cstore-preview__nameplate">
                {{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{/if}}
                <b>{{this.previewName}}</b>
              </span>
            {{else if (eq item.kind "card_decoration")}}
              <span class="cstore-preview__card">
                {{#if item.showMotionAsset}}
                  {{#if item.image_url}}<img src={{item.image_url}} alt="" loading="lazy" />{{/if}}
                {{/if}}
                <i></i><b>Kullanıcı kartı</b>
              </span>
            {{else}}
              <span class="cstore-preview__effect">
                <CosmeticsStoreProfileEffectLayers
                  @effect={{item}}
                  @stackOrder="back"
                />
                <span class="cstore-preview__effect-card"><i></i></span>
                {{#unless item.hasEffectLayers}}
                  {{#if item.showMotionAsset}}
                    {{#if item.image_url}}<img class="cstore-preview__effect-legacy" src={{item.image_url}} alt="" loading="lazy" />{{/if}}
                  {{/if}}
                {{/unless}}
                <CosmeticsStoreProfileEffectLayers
                  @effect={{item}}
                  @stackOrder="front"
                />
              </span>
            {{/if}}
            {{#if this.isBundle}}<small>{{item.name}}</small>{{/if}}
          </div>
        {{/each}}
      </div>
      {{#if this.isBundle}}<span class="cstore-preview__count">{{@product.item_count}} parça</span>{{/if}}
    </div>
  </template>
}
