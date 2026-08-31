import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const MAX_LOADOUTS = 10;
const SLOT_KINDS = [
  "avatar_frame",
  "nameplate",
  "card_decoration",
  "profile_effect",
];

export default class CosmeticsStoreLoadouts extends Component {
  @service dialog;

  @tracked loadouts = this.args.loadouts ?? [];
  @tracked newName = "";
  @tracked editingId = null;
  @tracked editingName = "";
  @tracked busyId = null;
  @tracked creating = false;
  @tracked notice = null;

  get rows() {
    const actionsDisabled = Boolean(this.busyId);

    return this.loadouts.map((loadout) => ({
      ...loadout,
      actions_disabled: actionsDisabled,
      apply_disabled: !loadout.can_apply || actionsDisabled,
      slot_rows: SLOT_KINDS.map((kind) => ({
        kind,
        label: i18n(`discourse_cosmetics_store.loadouts.kinds.${kind}`),
        ...(loadout.slots?.[kind] ?? {
          item_id: null,
          available: true,
          item: null,
        }),
      })),
    }));
  }

  get canCreate() {
    return (
      this.args.viewer?.logged_in &&
      this.loadouts.length < MAX_LOADOUTS &&
      this.newName.trim().length > 0 &&
      !this.creating
    );
  }

  get createDisabled() {
    return !this.canCreate;
  }

  get atLimit() {
    return this.loadouts.length >= MAX_LOADOUTS;
  }

  get renameSaveDisabled() {
    return !this.editingName.trim().length || Boolean(this.busyId);
  }

  get countLabel() {
    return i18n("discourse_cosmetics_store.loadouts.count", {
      count: this.loadouts.length,
      max: MAX_LOADOUTS,
    });
  }

  @action
  startRename(loadout) {
    this.notice = null;
    this.editingId = loadout.id;
    this.editingName = loadout.name;
  }

  @action
  cancelRename() {
    this.editingId = null;
    this.editingName = "";
  }

  @action
  async createLoadout(event) {
    event?.preventDefault();
    const name = this.newName.trim();
    if (!name || !this.canCreate) {
      return;
    }

    this.creating = true;
    this.notice = null;
    try {
      const payload = await ajax("/cosmetics-store/loadouts.json", {
        type: "POST",
        data: { name },
      });
      this.loadouts = [payload.loadout, ...this.loadouts];
      this.newName = "";
      this.notice = i18n("discourse_cosmetics_store.loadouts.created");
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.creating = false;
    }
  }

  @action
  async saveRename(loadout) {
    const name = this.editingName.trim();
    if (!name || this.busyId) {
      return;
    }

    this.busyId = loadout.id;
    this.notice = null;
    try {
      const payload = await ajax(`/cosmetics-store/loadouts/${loadout.id}.json`, {
        type: "PUT",
        data: { name },
      });
      this.loadouts = this.loadouts.map((row) =>
        row.id === loadout.id ? payload.loadout : row
      );
      this.cancelRename();
      this.notice = i18n("discourse_cosmetics_store.loadouts.renamed");
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyId = null;
    }
  }

  @action
  async applyLoadout(loadout) {
    if (!loadout.can_apply || this.busyId) {
      return;
    }

    this.busyId = loadout.id;
    this.notice = null;
    try {
      const payload = await ajax(
        `/cosmetics-store/loadouts/${loadout.id}/apply.json`,
        { type: "POST" }
      );
      this.loadouts = this.loadouts.map((row) =>
        row.id === loadout.id ? payload.loadout : row
      );
      this.notice = i18n("discourse_cosmetics_store.loadouts.applied", {
        name: payload.loadout.name,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyId = null;
    }
  }

  @action
  deleteLoadout(loadout) {
    if (this.busyId) {
      return;
    }

    return this.dialog.confirm({
      message: i18n("discourse_cosmetics_store.loadouts.delete_confirm", {
        name: loadout.name,
      }),
      didConfirm: () => this.performDeleteLoadout(loadout),
    });
  }

  async performDeleteLoadout(loadout) {
    this.busyId = loadout.id;
    this.notice = null;
    try {
      await ajax(`/cosmetics-store/loadouts/${loadout.id}.json`, {
        type: "DELETE",
      });
      this.loadouts = this.loadouts.filter((row) => row.id !== loadout.id);
      if (this.editingId === loadout.id) {
        this.cancelRename();
      }
      this.notice = i18n("discourse_cosmetics_store.loadouts.deleted");
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busyId = null;
    }
  }

  <template>
    <div class="cstore-shell cstore-loadouts" data-testid="cosmetics-loadouts">
      <section class="cstore-loadouts__hero">
        <div>
          <p class="cstore-eyebrow">
            {{i18n "discourse_cosmetics_store.loadouts.eyebrow"}}
          </p>
          <h1>{{i18n "discourse_cosmetics_store.loadouts.title"}}</h1>
          <p>{{i18n "discourse_cosmetics_store.loadouts.subtitle"}}</p>
        </div>
        <div class="cstore-loadouts__hero-actions">
          <span data-testid="loadout-count">{{this.countLabel}}</span>
          <DButton
            class="btn-default"
            @href="/store/inventory"
            @label="discourse_cosmetics_store.nav.inventory"
          />
        </div>
      </section>

      {{#if this.notice}}
        <div class="cstore-notice" role="status">✓ {{this.notice}}</div>
      {{/if}}

      <section class="cstore-loadouts__create">
        <div>
          <h2>{{i18n "discourse_cosmetics_store.loadouts.create_title"}}</h2>
          <p>{{i18n "discourse_cosmetics_store.loadouts.create_description"}}</p>
        </div>
        <form {{on "submit" this.createLoadout}}>
          <Input
            data-testid="loadout-name-input"
            @type="text"
            @value={{this.newName}}
            maxlength="80"
            placeholder={{i18n "discourse_cosmetics_store.loadouts.name_placeholder"}}
            disabled={{this.creating}}
          />
          <DButton
            class="btn-primary"
            data-testid="create-loadout"
            @type="submit"
            @disabled={{this.createDisabled}}
            @label={{if
              this.creating
              "discourse_cosmetics_store.loadouts.saving"
              "discourse_cosmetics_store.loadouts.create_action"
            }}
          />
        </form>
        {{#if this.atLimit}}
          <small class="cstore-loadouts__limit">
            {{i18n "discourse_cosmetics_store.loadouts.limit_reached"}}
          </small>
        {{/if}}
      </section>

      {{#if this.rows.length}}
        <section class="cstore-loadouts__grid">
          {{#each this.rows as |loadout|}}
            <article
              class="cstore-loadout-card {{unless loadout.can_apply 'is-unavailable'}}"
              data-loadout-id={{loadout.id}}
            >
              <header class="cstore-loadout-card__header">
                <div>
                  {{#if (eq this.editingId loadout.id)}}
                    <Input
                      data-testid="rename-loadout-input"
                      @type="text"
                      @value={{this.editingName}}
                      maxlength="80"
                    />
                  {{else}}
                    <h2>{{loadout.name}}</h2>
                  {{/if}}
                  <span>
                    {{#if loadout.can_apply}}
                      {{i18n "discourse_cosmetics_store.loadouts.ready"}}
                    {{else}}
                      {{i18n "discourse_cosmetics_store.loadouts.unavailable"}}
                    {{/if}}
                  </span>
                </div>
                <span class="cstore-loadout-card__status" aria-hidden="true">
                  {{if loadout.can_apply "✓" "!"}}
                </span>
              </header>

              <div class="cstore-loadout-card__slots">
                {{#each loadout.slot_rows as |slot|}}
                  <div
                    class="cstore-loadout-slot {{unless slot.available 'is-unavailable'}}"
                    data-slot-kind={{slot.kind}}
                  >
                    <div class="cstore-loadout-slot__preview">
                      {{#if slot.item}}
                        {{#if slot.item.image_url}}
                          <img src={{slot.item.image_url}} alt="" loading="lazy" />
                        {{else}}
                          <span aria-hidden="true">◇</span>
                        {{/if}}
                      {{else}}
                        <span aria-hidden="true">◇</span>
                      {{/if}}
                    </div>
                    <div>
                      <small>{{slot.label}}</small>
                      <strong>
                        {{#if slot.item}}
                          {{slot.item.name}}
                        {{else}}
                          {{i18n "discourse_cosmetics_store.loadouts.empty_slot"}}
                        {{/if}}
                      </strong>
                      {{#unless slot.available}}
                        <em>{{i18n "discourse_cosmetics_store.loadouts.slot_unavailable"}}</em>
                      {{/unless}}
                    </div>
                  </div>
                {{/each}}
              </div>

              <footer class="cstore-loadout-card__actions">
                {{#if (eq this.editingId loadout.id)}}
                  <DButton
                    class="btn-primary"
                    @action={{fn this.saveRename loadout}}
                    @disabled={{this.renameSaveDisabled}}
                    @label="discourse_cosmetics_store.loadouts.save_name"
                  />
                  <DButton
                    class="btn-default"
                    @action={{this.cancelRename}}
                    @disabled={{loadout.actions_disabled}}
                    @label="discourse_cosmetics_store.loadouts.cancel"
                  />
                {{else}}
                  <DButton
                    class="btn-primary"
                    data-testid="apply-loadout"
                    @action={{fn this.applyLoadout loadout}}
                    @disabled={{loadout.apply_disabled}}
                    @label="discourse_cosmetics_store.loadouts.apply_action"
                  />
                  <DButton
                    class="btn-default"
                    data-testid="rename-loadout"
                    @action={{fn this.startRename loadout}}
                    @disabled={{loadout.actions_disabled}}
                    @label="discourse_cosmetics_store.loadouts.rename_action"
                  />
                  <DButton
                    class="btn-danger"
                    data-testid="delete-loadout"
                    @action={{fn this.deleteLoadout loadout}}
                    @disabled={{loadout.actions_disabled}}
                    @icon="trash-can"
                    @label="discourse_cosmetics_store.loadouts.delete_action"
                  />
                {{/if}}
              </footer>
            </article>
          {{/each}}
        </section>
      {{else}}
        <section class="cstore-empty cstore-loadouts__empty">
          <strong>{{i18n "discourse_cosmetics_store.loadouts.empty_title"}}</strong>
          <p>{{i18n "discourse_cosmetics_store.loadouts.empty_description"}}</p>
        </section>
      {{/if}}
    </div>
  </template>
}
