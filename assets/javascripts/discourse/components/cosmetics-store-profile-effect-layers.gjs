import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

const CARD_WIDTH = 304;
const CARD_HEIGHT = 444;
const DEFAULT_INNER_WIDTH = 1200;
const VALID_ANCHORS = new Set(["top", "bottom", "left", "right", "full"]);

function nonNegativeNumber(value, fallback = 0) {
  const number = Number(value);

  return Number.isFinite(number) && number >= 0 ? number : fallback;
}

export default class CosmeticsStoreProfileEffectLayers extends Component {
  get effect() {
    return this.args.effect ?? {};
  }

  get layers() {
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
    const innerWidth = Math.max(
      nonNegativeNumber(
        this.effect.effect_inner_width ?? this.effect.inner_width,
        DEFAULT_INNER_WIDTH,
      ),
      1,
    );
    const overflowTop = nonNegativeNumber(
      this.effect.effect_overflow_top ?? this.effect.overflow_top,
    );
    const overflowBottom = nonNegativeNumber(
      this.effect.effect_overflow_bottom ?? this.effect.overflow_bottom,
    );
    const overflowHorizontal = nonNegativeNumber(
      this.effect.effect_overflow_horizontal ??
        this.effect.overflow_horizontal,
    );
    const sideOffsetTop = nonNegativeNumber(
      this.effect.effect_side_offset_top ?? this.effect.side_offset_top,
    );
    const sideOffsetBottom = nonNegativeNumber(
      this.effect.effect_side_offset_bottom ?? this.effect.side_offset_bottom,
    );
    const cardHeight = innerWidth * (CARD_HEIGHT / CARD_WIDTH);
    const stageWidth = innerWidth + overflowHorizontal * 2;
    const stageHeight = cardHeight + overflowTop + overflowBottom;

    return htmlSafe(
      `--cstore-effect-left:${(-overflowHorizontal / innerWidth) * 100}%;` +
        `--cstore-effect-width:${(stageWidth / innerWidth) * 100}%;` +
        `--cstore-effect-ratio:${stageWidth} / ${stageHeight};` +
        `--cstore-effect-shift-y:${(-overflowTop / stageHeight) * 100}%;` +
        `--cstore-effect-side-top:${(sideOffsetTop / stageHeight) * 100}%;` +
        `--cstore-effect-side-bottom:${(sideOffsetBottom / stageHeight) * 100}%`,
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
