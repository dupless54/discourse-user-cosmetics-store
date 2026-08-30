import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { prefersReducedMotion } from "../lib/cosmetics-store-motion";

const CARD_WIDTH = 304;
const CARD_HEIGHT = 444;
const DEFAULT_INNER_WIDTH = 1200;
const VALID_ANCHORS = new Set(["top", "bottom", "left", "right", "full"]);

function nonNegativeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0 ? number : fallback;
}

export function profileEffectGeometry(effect = {}) {
  const innerWidth = Math.max(
    nonNegativeNumber(
      effect.effect_inner_width ?? effect.inner_width,
      DEFAULT_INNER_WIDTH,
    ),
    1,
  );
  const overflowTop = nonNegativeNumber(
    effect.effect_overflow_top ?? effect.overflow_top,
  );
  const overflowBottom = nonNegativeNumber(
    effect.effect_overflow_bottom ?? effect.overflow_bottom,
  );
  const overflowHorizontal = nonNegativeNumber(
    effect.effect_overflow_horizontal ?? effect.overflow_horizontal,
  );
  const sideOffsetTop = nonNegativeNumber(
    effect.effect_side_offset_top ?? effect.side_offset_top,
  );
  const sideOffsetBottom = nonNegativeNumber(
    effect.effect_side_offset_bottom ?? effect.side_offset_bottom,
  );
  const cardHeight = innerWidth * (CARD_HEIGHT / CARD_WIDTH);
  const stageWidth = innerWidth + overflowHorizontal * 2;
  const stageHeight = cardHeight + overflowTop + overflowBottom;

  return {
    innerWidth,
    overflowTop,
    overflowBottom,
    overflowHorizontal,
    sideOffsetTop,
    sideOffsetBottom,
    cardHeight,
    stageWidth,
    stageHeight,
  };
}

export default class CosmeticsStoreProfileEffectLayers extends Component {
  get effect() {
    return this.args.effect ?? {};
  }

  get layers() {
    if (prefersReducedMotion()) {
      return [];
    }

    return (Array.isArray(this.effect.layers) ? this.effect.layers : [])
      .filter(
        (layer) =>
          layer?.image_url && layer.stack_order === this.args.stackOrder,
      )
      .map((layer) => ({
        ...layer,
        anchor: VALID_ANCHORS.has(layer.anchor) ? layer.anchor : "top",
      }));
  }

  get geometryStyle() {
    const geometry = profileEffectGeometry(this.effect);

    return htmlSafe(
      `--cstore-effect-left:${(-geometry.overflowHorizontal / geometry.innerWidth) * 100}%;` +
        `--cstore-effect-width:${(geometry.stageWidth / geometry.innerWidth) * 100}%;` +
        `--cstore-effect-ratio:${geometry.stageWidth} / ${geometry.stageHeight};` +
        `--cstore-effect-shift-y:${(-geometry.overflowTop / geometry.stageHeight) * 100}%;` +
        `--cstore-effect-side-top:${(geometry.sideOffsetTop / geometry.stageHeight) * 100}%;` +
        `--cstore-effect-side-bottom:${(geometry.sideOffsetBottom / geometry.stageHeight) * 100}%`,
    );
  }

  <template>
    {{#if this.layers.length}}
      <div
        class="cstore-profile-effect-layers cstore-profile-effect-layers--{{@stackOrder}}"
        style={{this.geometryStyle}}
        aria-hidden="true"
      >
        {{#each this.layers as |layer|}}
          <img
            class="cstore-profile-effect-layers__image cstore-profile-effect-layers__image--{{layer.anchor}}"
            src={{layer.image_url}}
            alt=""
            loading="eager"
          />
        {{/each}}
      </div>
    {{/if}}
  </template>
}
