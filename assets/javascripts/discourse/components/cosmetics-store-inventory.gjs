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
    <div class="cstore-shell" data-testid="cosmetics-inventory">
      {{#if @viewer.logged_in}}
        <main class="cstore-section cstore-favorites-page">
          <div class="cstore-section__heading">
            <div>
              <p class="cstore-eyebrow">
                {{i18n "discourse_cosmetics_store.inventory.eyebrow"}}
              </p>
              <h1>{{i18n "discourse_cosmetics_store.inventory.title"}}</h1>
              <span>{{i18n "discourse_cosmetics_store.inventory.subtitle"}}</span>
            </div>
            <div>
              <a class="btn btn-default" href="/store">
                {{i18n "discourse_cosmetics_store.title"}}
              </a>
              <a class="btn btn-default" href="/store/loadouts">
                {{i18n "discourse_cosmetics_store.nav.loadouts"}}
              </a>
              <a class="btn btn-primary" href="/my/preferences/cosmetics">
                {{dIcon "check"}}
                {{i18n "discourse_cosmetics_store.inventory.manage_action"}}
              </a>
            </div>
          </div>

          <div class="cstore-wallet-stats">
            <span data-testid="inventory-owned-count">
              <strong>{{this.stats.directly_owned_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.directly_owned"}}</small>
            </span>
            <span data-testid="inventory-unlocked-count">
              <strong>{{this.stats.unlocked_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.unlocked"}}</small>
            </span>
            <span data-testid="inventory-catalog-count">
              <strong>{{this.stats.catalog_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.inventory.catalog"}}</small>
            </span>
          </div>

          <div class="cstore-results__bar">
            <div>
              <button
                type="button"
                data-testid="inventory-mode-owned"
                class={{if (eq this.mode "owned") "btn btn-primary" "btn btn-default"}}
                aria-pressed={{eq this.mode "owned"}}
                {{on "click" (fn this.setMode "owned")}}
              >
                {{i18n "discourse_cosmetics_store.inventory.mode_owned"}}
              </button>
              <button
                type="button"
                data-testid="inventory-mode-unlocked"
                class={{if (eq this.mode "unlocked") "btn btn-primary" "btn btn-default"}}
                aria-pressed={{eq this.mode "unlocked"}}
                {{on "click" (fn this.setMode "unlocked")}}
              >
                {{i18n "discourse_cosmetics_store.inventory.mode_unlocked"}}
              </button>
            </div>

            <label>
              {{i18n "discourse_cosmetics_store.inventory.filter_kind"}}
              <select
                data-testid="inventory-kind-filter"
                value={{this.selectedKind}}
                {{on "change" this.updateKind}}
              >
                <option value="">{{i18n "discourse_cosmetics_store.inventory.all_kinds"}}</option>
                {{#each this.kindOptions as |kind|}}
                  <option value={{kind.kind}}>{{kind.label}} ({{kind.visible_count}})</option>
                {{/each}}
              </select>
            </label>
          </div>

          {{#if this.visibleItems.length}}
            <div class="cstore-grid">
              {{#each this.visibleItems as |item|}}
                <article
                  class="cstore-product {{if item.directly_owned 'is-owned'}}"
                  data-item-id={{item.id}}
                >
                  <div class="cstore-product__open">
                    {{#if item.image_url}}
                      <img src={{item.image_url}} alt="" loading="lazy" />
                    {{else}}
                      <span aria-hidden="true">{{dIcon "image"}}</span>
                    {{/if}}
                  </div>

                  <div class="cstore-product__info">
                    <span class="cstore-product__meta">
                      {{#if item.directly_owned}}
                        <i>{{dIcon "check"}} {{i18n "discourse_cosmetics_store.inventory.owned_badge"}}</i>
                      {{else if item.unlocked}}
                        <i>{{dIcon "eye"}} {{i18n "discourse_cosmetics_store.inventory.unlocked_badge"}}</i>
                      {{/if}}
                      {{#if item.is_default}}
                        <i>{{i18n "discourse_cosmetics_store.inventory.default_badge"}}</i>
                      {{/if}}
                    </span>
                    <strong>{{item.name}}</strong>
                    <small>{{item.kind_label}}</small>
                    {{#if item.description}}<p>{{item.description}}</p>{{/if}}
                    {{#if item.rarity_label}}
                      <span class="cstore-product__price">{{item.rarity_label}}</span>
                    {{/if}}
                  </div>
                </article>
              {{/each}}
            </div>
          {{else}}
            <section class="cstore-empty">
              <strong>{{this.emptyTitle}}</strong>
              <p>{{this.emptyDescription}}</p>
            </section>
          {{/if}}
        </main>
      {{else}}
        <main class="cstore-section cstore-favorites-page">
          <section class="cstore-empty">
            <strong>{{i18n "discourse_cosmetics_store.inventory.login_title"}}</strong>
            <p>{{i18n "discourse_cosmetics_store.inventory.login_description"}}</p>
            <a class="btn btn-primary" href="/login?return_path=%2Fstore%2Finventory">
              {{i18n "discourse_cosmetics_store.inventory.login_action"}}
            </a>
          </section>
        </main>
      {{/if}}
    </div>
  </template>
}
