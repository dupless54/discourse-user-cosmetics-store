import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const EMPTY_INVENTORY = {
  items: [],
  kinds: [],
  stats: {
    catalog_count: 0,
    visible_count: 0,
    directly_owned_count: 0,
    unlocked_count: 0,
  },
};

export default class CosmeticsStoreInventory extends Component {
  @tracked mode = "owned";
  @tracked selectedKind = "";

  get inventory() {
    return this.args.inventory ?? EMPTY_INVENTORY;
  }

  get stats() {
    return this.inventory.stats ?? EMPTY_INVENTORY.stats;
  }

  get kindOptions() {
    return (this.inventory.kinds ?? []).map((row) => ({
      ...row,
      label: this.kindLabel(row.kind),
    }));
  }

  get visibleItems() {
    return (this.inventory.items ?? [])
      .filter((item) =>
        this.mode === "owned" ? item.directly_owned : item.unlocked
      )
      .filter((item) => !this.selectedKind || item.kind === this.selectedKind)
      .map((item) => ({
        ...item,
        kind_label: this.kindLabel(item.kind),
      }));
  }

  get emptyTitle() {
    return i18n(
      this.mode === "owned"
        ? "discourse_cosmetics_store.inventory.empty_owned_title"
        : "discourse_cosmetics_store.inventory.empty_unlocked_title"
    );
  }

  get emptyDescription() {
    return i18n(
      this.mode === "owned"
        ? "discourse_cosmetics_store.inventory.empty_owned_description"
        : "discourse_cosmetics_store.inventory.empty_unlocked_description"
    );
  }

  kindLabel(kind) {
    return i18n(`discourse_cosmetics_store.inventory.kinds.${kind}`);
  }

  @action
  setMode(mode) {
    if (mode === "owned" || mode === "unlocked") {
      this.mode = mode;
    }
  }

  @action
  updateKind(event) {
    this.selectedKind = event.target.value;
  }

  <template>
    {{#if @viewer.logged_in}}
      <main class="cstore-inventory-page">
        <section class="cstore-inventory-hero">
          <div>
            <p class="cstore-eyebrow">
              {{i18n "discourse_cosmetics_store.inventory.eyebrow"}}
            </p>
            <h1>{{i18n "discourse_cosmetics_store.inventory.title"}}</h1>
            <p>{{i18n "discourse_cosmetics_store.inventory.subtitle"}}</p>
          </div>
          <a class="btn btn-default" href="/my/preferences/cosmetics">
            {{dIcon "check"}}
            {{i18n "discourse_cosmetics_store.inventory.manage_action"}}
          </a>
        </section>

        <section class="cstore-inventory-stats" aria-label={{i18n "discourse_cosmetics_store.inventory.title"}}>
          <article>
            <span>{{dIcon "check"}}</span>
            <div>
              <strong>{{this.stats.directly_owned_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.directly_owned"}}</small>
            </div>
          </article>
          <article>
            <span>{{dIcon "eye"}}</span>
            <div>
              <strong>{{this.stats.unlocked_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.unlocked"}}</small>
            </div>
          </article>
          <article>
            <span>{{dIcon "image"}}</span>
            <div>
              <strong>{{this.stats.catalog_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.catalog"}}</small>
            </div>
          </article>
        </section>

        <section class="cstore-inventory-toolbar">
          <div class="cstore-inventory-modes" role="group" aria-label={{i18n "discourse_cosmetics_store.inventory.title"}}>
            <button
              type="button"
              class={{if (eq this.mode "owned") "is-active"}}
              aria-pressed={{eq this.mode "owned"}}
              {{on "click" (fn this.setMode "owned")}}
            >
              {{i18n "discourse_cosmetics_store.inventory.mode_owned"}}
            </button>
            <button
              type="button"
              class={{if (eq this.mode "unlocked") "is-active"}}
              aria-pressed={{eq this.mode "unlocked"}}
              {{on "click" (fn this.setMode "unlocked")}}
            >
              {{i18n "discourse_cosmetics_store.inventory.mode_unlocked"}}
            </button>
          </div>

          <label>
            <span>{{i18n "discourse_cosmetics_store.inventory.filter_kind"}}</span>
            <select value={{this.selectedKind}} {{on "change" this.updateKind}}>
              <option value="">{{i18n "discourse_cosmetics_store.inventory.all_kinds"}}</option>
              {{#each this.kindOptions as |kind|}}
                <option value={{kind.kind}}>{{kind.label}} ({{kind.visible_count}})</option>
              {{/each}}
            </select>
          </label>
        </section>

        {{#if this.visibleItems.length}}
          <section class="cstore-inventory-grid">
            {{#each this.visibleItems as |item|}}
              <article class="cstore-inventory-card {{if item.directly_owned 'is-owned' 'is-unlocked'}}">
                <div class="cstore-inventory-card__preview">
                  {{#if item.image_url}}
                    <img src={{item.image_url}} alt="" loading="lazy" />
                  {{else}}
                    <span aria-hidden="true">{{dIcon "image"}}</span>
                  {{/if}}
                </div>

                <div class="cstore-inventory-card__body">
                  <div class="cstore-inventory-card__badges">
                    {{#if item.directly_owned}}
                      <span class="is-owned">{{dIcon "check"}} {{i18n "discourse_cosmetics_store.inventory.owned_badge"}}</span>
                    {{else if item.unlocked}}
                      <span>{{dIcon "eye"}} {{i18n "discourse_cosmetics_store.inventory.unlocked_badge"}}</span>
                    {{/if}}
                    {{#if item.is_default}}
                      <span>{{i18n "discourse_cosmetics_store.inventory.default_badge"}}</span>
                    {{/if}}
                  </div>
                  <strong>{{item.name}}</strong>
                  <small>{{item.kind_label}}</small>
                  {{#if item.description}}<p>{{item.description}}</p>{{/if}}
                  {{#if item.rarity_label}}<em>{{item.rarity_label}}</em>{{/if}}
                </div>
              </article>
            {{/each}}
          </section>
        {{else}}
          <section class="cstore-empty cstore-inventory-empty">
            <strong>{{this.emptyTitle}}</strong>
            <p>{{this.emptyDescription}}</p>
          </section>
        {{/if}}
      </main>
    {{else}}
      <main class="cstore-section cstore-inventory-page">
        <section class="cstore-empty">
          <strong>{{i18n "discourse_cosmetics_store.inventory.login_title"}}</strong>
          <p>{{i18n "discourse_cosmetics_store.inventory.login_description"}}</p>
          <a class="btn btn-primary" href="/login?return_path=%2Fstore%2Finventory">
            {{i18n "discourse_cosmetics_store.inventory.login_action"}}
          </a>
        </section>
      </main>
    {{/if}}
  </template>
}
