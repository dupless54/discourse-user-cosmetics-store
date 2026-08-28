import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
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
  @tracked equippedItemIds = {};
  @tracked busyKind = null;
  @tracked notice = null;

  constructor(owner, args) {
    super(owner, args);
    this.equippedItemIds = Object.fromEntries(
      (args.inventory?.items ?? [])
        .filter((item) => item.equipped)
        .map((item) => [item.kind, item.id])
    );
  }

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
        equipped: this.equippedItemIds[item.kind] === item.id,
        action_disabled: Boolean(this.busyKind),
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

  @action
  async equipItem(item) {
    if (!this.args.viewer?.can_manage_selection || this.busyKind) {
      return;
    }

    this.busyKind = item.kind;
    this.notice = null;
    try {
      const payload = await ajax(
        `/cosmetics-store/inventory/${item.id}/equip.json`,
        { type: "PUT" }
      );
      this.equippedItemIds = { ...(payload.equipped_item_ids ?? {}) };
      this.notice = i18n("discourse_cosmetics_store.inventory.equipped", {
        name: item.name,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyKind = null;
    }
  }

  @action
  async unequipItem(item) {
    if (!this.args.viewer?.can_manage_selection || this.busyKind) {
      return;
    }

    this.busyKind = item.kind;
    this.notice = null;
    try {
      const payload = await ajax(
        `/cosmetics-store/inventory/${item.kind}/equip.json`,
        { type: "DELETE" }
      );
      this.equippedItemIds = { ...(payload.equipped_item_ids ?? {}) };
      this.notice = i18n("discourse_cosmetics_store.inventory.unequipped", {
        name: item.name,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyKind = null;
    }
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

          {{#if this.notice}}
            <div class="cstore-notice" role="status">✓ {{this.notice}}</div>
          {{/if}}

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
                  class="cstore-product cstore-inventory-card {{if item.directly_owned 'is-owned'}} {{if item.equipped 'is-equipped'}}"
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
                      {{#if item.equipped}}
                        <i class="cstore-inventory-card__equipped">
                          {{dIcon "check"}}
                          {{i18n "discourse_cosmetics_store.inventory.equipped_badge"}}
                        </i>
                      {{else if item.directly_owned}}
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

                  {{#if @viewer.can_manage_selection}}
                    <div class="cstore-inventory-card__actions">
                      {{#if item.equipped}}
                        <button
                          class="btn btn-default"
                          data-testid="unequip-cosmetic"
                          type="button"
                          disabled={{item.action_disabled}}
                          {{on "click" (fn this.unequipItem item)}}
                        >
                          {{dIcon "xmark"}}
                          {{i18n "discourse_cosmetics_store.inventory.unequip_action"}}
                        </button>
                      {{else}}
                        <button
                          class="btn btn-primary"
                          data-testid="equip-cosmetic"
                          type="button"
                          disabled={{item.action_disabled}}
                          {{on "click" (fn this.equipItem item)}}
                        >
                          {{dIcon "check"}}
                          {{i18n "discourse_cosmetics_store.inventory.equip_action"}}
                        </button>
                      {{/if}}
                    </div>
                  {{/if}}
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
