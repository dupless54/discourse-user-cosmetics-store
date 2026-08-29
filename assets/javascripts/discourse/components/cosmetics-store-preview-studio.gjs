import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { prefersReducedMotion } from "../lib/cosmetics-store-motion";
import CosmeticsStoreProfileEffectLayers from "./cosmetics-store-profile-effect-layers";

const SLOT_KINDS = [
  "avatar_frame",
  "nameplate",
  "card_decoration",
  "profile_effect",
];
const MOTION_HEAVY_KINDS = new Set(["card_decoration", "profile_effect"]);

export default class CosmeticsStorePreviewStudio extends Component {
  @tracked selections;
  @tracked savedSelections;
  @tracked applying = false;
  @tracked notice = null;

  constructor() {
    super(...arguments);
    const initial = this.normalizeSelections(this.args.selections);
    this.savedSelections = initial;
    this.selections = { ...initial };
  }

  get items() {
    return this.args.items ?? [];
  }

  get slotRows() {
    const reduceMotion = prefersReducedMotion();

    return SLOT_KINDS.map((kind) => ({
      kind,
      label: i18n(`discourse_cosmetics_store.preview.kinds.${kind}`),
      selectedId: this.selections[kind],
      options: this.items
        .filter((item) => item.kind === kind)
        .map((item) => ({
          ...item,
          selected: this.selections[kind] === item.id,
          showThumbnailImage:
            Boolean(item.image_url) &&
            (!reduceMotion || !MOTION_HEAVY_KINDS.has(kind)),
        })),
    }));
  }

  get avatarFrame() {
    return this.selectedItem("avatar_frame");
  }

  get nameplate() {
    return this.selectedItem("nameplate");
  }

  get cardDecoration() {
    return this.selectedItem("card_decoration");
  }

  get profileEffect() {
    return this.selectedItem("profile_effect");
  }

  get avatarUrl() {
    const template = this.args.viewer?.avatar_template;
    return template ? String(template).replace("{size}", "160") : null;
  }

  get hasChanges() {
    return SLOT_KINDS.some(
      (kind) => this.selections[kind] !== this.savedSelections[kind]
    );
  }

  get applyDisabled() {
    return this.applying || !this.hasChanges;
  }

  get nameplateStyle() {
    const item = this.nameplate;
    if (!item?.gradient_from || !item?.gradient_to) {
      return htmlSafe("");
    }

    const glow = item.glow_color
      ? `;box-shadow:0 0 18px ${item.glow_color}`
      : "";

    return htmlSafe(
      `background:linear-gradient(135deg,${item.gradient_from},${item.gradient_to})${glow}`
    );
  }

  get showCardDecorationImage() {
    return Boolean(
      this.cardDecoration?.image_url && !prefersReducedMotion(),
    );
  }

  get hasCardDecorationGradient() {
    return Boolean(
      this.cardDecoration?.gradient_from && this.cardDecoration?.gradient_to,
    );
  }

  get cardDecorationStyle() {
    const item = this.cardDecoration;
    if (!item?.gradient_from || !item?.gradient_to) {
      return htmlSafe("");
    }

    return htmlSafe(
      `background:linear-gradient(135deg,${item.gradient_from},${item.gradient_to})`
    );
  }

  selectedItem(kind) {
    const id = this.selections[kind];
    return id ? this.items.find((item) => item.id === id) : null;
  }

  normalizeSelections(selections) {
    const source = selections ?? {};

    return SLOT_KINDS.reduce((result, kind) => {
      const raw = source[kind];
      const id = Number(raw);
      result[kind] =
        raw === null ||
        raw === undefined ||
        raw === "" ||
        !Number.isInteger(id) ||
        id <= 0
          ? null
          : id;
      return result;
    }, {});
  }

  @action
  selectItemForSlot(kind, itemId) {
    this.notice = null;
    this.selections = { ...this.selections, [kind]: itemId };
  }

  @action
  resetPreview() {
    this.notice = null;
    this.selections = { ...this.savedSelections };
  }

  @action
  async applyPreview() {
    if (this.applyDisabled) {
      return;
    }

    this.applying = true;
    this.notice = null;

    try {
      const payload = await ajax("/cosmetics-store/preview/apply.json", {
        type: "POST",
        data: { selections: this.selections },
      });
      const applied = this.normalizeSelections(payload.selections);
      this.savedSelections = applied;
      this.selections = { ...applied };
      this.notice = i18n("discourse_cosmetics_store.preview.applied");
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.applying = false;
    }
  }

  <template>
    <div class="cstore-shell cstore-preview-studio" data-testid="cosmetics-preview-studio">
      <section class="cstore-preview-studio__hero">
        <div>
          <p class="cstore-eyebrow">
            {{i18n "discourse_cosmetics_store.preview.eyebrow"}}
          </p>
          <h1>{{i18n "discourse_cosmetics_store.preview.title"}}</h1>
          <p>{{i18n "discourse_cosmetics_store.preview.subtitle"}}</p>
        </div>
        <div class="cstore-preview-studio__hero-actions">
          <a class="btn btn-default" href="/store/inventory">
            {{i18n "discourse_cosmetics_store.nav.inventory"}}
          </a>
          <a class="btn btn-default" href="/store/loadouts">
            {{i18n "discourse_cosmetics_store.nav.loadouts"}}
          </a>
        </div>
      </section>

      {{#if this.notice}}
        <div class="cstore-notice" role="status">
          {{dIcon "check"}} {{this.notice}}
        </div>
      {{/if}}

      <div class="cstore-preview-studio__layout">
        <section
          class="cstore-preview-studio__controls"
          aria-label={{i18n "discourse_cosmetics_store.preview.controls_label"}}
        >
          {{#each this.slotRows as |slot|}}
            <fieldset class="cstore-preview-slot" data-slot-kind={{slot.kind}}>
              <legend>{{slot.label}}</legend>
              <div class="cstore-preview-slot__options">
                <button
                  type="button"
                  class="cstore-preview-choice {{if (eq slot.selectedId null) 'is-selected'}}"
                  aria-pressed={{eq slot.selectedId null}}
                  data-testid="preview-none-{{slot.kind}}"
                  {{on "click" (fn this.selectItemForSlot slot.kind null)}}
                >
                  <span class="cstore-preview-choice__thumb is-empty" aria-hidden="true">×</span>
                  <span>{{i18n "discourse_cosmetics_store.preview.none"}}</span>
                </button>

                {{#each slot.options as |item|}}
                  <button
                    type="button"
                    class="cstore-preview-choice {{if item.selected 'is-selected'}}"
                    aria-pressed={{item.selected}}
                    data-item-id={{item.id}}
                    {{on "click" (fn this.selectItemForSlot slot.kind item.id)}}
                  >
                    <span class="cstore-preview-choice__thumb">
                      {{#if item.showThumbnailImage}}
                        <img src={{item.image_url}} alt="" loading="lazy" />
                      {{else}}
                        {{dIcon "palette"}}
                      {{/if}}
                    </span>
                    <span>
                      <strong>{{item.name}}</strong>
                      {{#if item.rarity_label}}
                        <small>{{item.rarity_label}}</small>
                      {{/if}}
                    </span>
                  </button>
                {{/each}}
              </div>

              {{#unless slot.options.length}}
                <p class="cstore-preview-slot__empty">
                  {{i18n "discourse_cosmetics_store.preview.empty_kind"}}
                </p>
              {{/unless}}
            </fieldset>
          {{/each}}
        </section>

        <aside class="cstore-preview-studio__stage-panel">
          <div class="cstore-preview-studio__stage-heading">
            <div>
              <small>
                {{i18n "discourse_cosmetics_store.preview.preview_eyebrow"}}
              </small>
              <h2>{{i18n "discourse_cosmetics_store.preview.preview_title"}}</h2>
            </div>
            <span>{{i18n "discourse_cosmetics_store.preview.temporary_note"}}</span>
          </div>

          <div class="cstore-preview-studio__effect-wrap">
            {{#if this.profileEffect}}
              <CosmeticsStoreProfileEffectLayers
                @effect={{this.profileEffect}}
                @stackOrder="back"
              />
            {{/if}}

            <article class="cstore-preview-studio-card">
              {{#if this.cardDecoration}}
                {{#if this.showCardDecorationImage}}
                  <img
                    class="cstore-preview-studio-card__decoration"
                    src={{this.cardDecoration.image_url}}
                    alt=""
                    aria-hidden="true"
                  />
                {{else if this.hasCardDecorationGradient}}
                  <div
                    class="cstore-preview-studio-card__decoration-gradient"
                    style={{this.cardDecorationStyle}}
                    aria-hidden="true"
                  ></div>
                {{/if}}
              {{/if}}

              <div class="cstore-preview-studio-card__cover" aria-hidden="true"></div>
              <div class="cstore-preview-studio-card__body">
                <div class="cstore-preview-studio-avatar">
                  {{#if this.avatarUrl}}
                    <img
                      class="cstore-preview-studio-avatar__photo"
                      src={{this.avatarUrl}}
                      alt={{@viewer.username}}
                    />
                  {{else}}
                    <span class="cstore-preview-studio-avatar__fallback" aria-hidden="true">
                      {{dIcon "image"}}
                    </span>
                  {{/if}}

                  {{#if this.avatarFrame.image_url}}
                    <img
                      class="cstore-preview-studio-avatar__frame"
                      src={{this.avatarFrame.image_url}}
                      alt=""
                      aria-hidden="true"
                    />
                  {{/if}}
                </div>

                <div class="cstore-preview-studio-card__identity">
                  <strong>@{{@viewer.username}}</strong>
                  {{#if this.nameplate}}
                    <span
                      class="cstore-preview-studio-nameplate"
                      style={{this.nameplateStyle}}
                    >
                      {{this.nameplate.name}}
                    </span>
                  {{else}}
                    <span class="cstore-preview-studio-card__plain-name">
                      {{@viewer.username}}
                    </span>
                  {{/if}}
                  <p>{{i18n "discourse_cosmetics_store.preview.sample_bio"}}</p>
                </div>
              </div>
            </article>

            {{#if this.profileEffect}}
              <CosmeticsStoreProfileEffectLayers
                @effect={{this.profileEffect}}
                @stackOrder="front"
              />
            {{/if}}
          </div>

          <div class="cstore-preview-studio__actions">
            <button
              type="button"
              class="btn btn-primary"
              data-testid="apply-preview"
              disabled={{this.applyDisabled}}
              {{on "click" this.applyPreview}}
            >
              {{#if this.applying}}
                {{i18n "discourse_cosmetics_store.preview.applying"}}
              {{else}}
                {{i18n "discourse_cosmetics_store.preview.apply_action"}}
              {{/if}}
            </button>
            <button
              type="button"
              class="btn btn-default"
              data-testid="reset-preview"
              disabled={{this.applying}}
              {{on "click" this.resetPreview}}
            >
              {{i18n "discourse_cosmetics_store.preview.reset_action"}}
            </button>
          </div>
        </aside>
      </div>
    </div>
  </template>
}
