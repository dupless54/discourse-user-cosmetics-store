import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const EMPTY_HISTORY = {
  purchases: [],
  gifts_sent: [],
  gifts_received: [],
  stats: {
    purchase_count: 0,
    gifts_sent_count: 0,
    gifts_received_count: 0,
  },
  limits: {
    purchases: 100,
    gifts_sent: 100,
    gifts_received: 100,
  },
  currency_symbol: "",
};

export default class CosmeticsStoreHistory extends Component {
  @tracked mode = "purchases";

  get history() {
    return this.args.history ?? EMPTY_HISTORY;
  }

  get stats() {
    return this.history.stats ?? EMPTY_HISTORY.stats;
  }

  get tabs() {
    return [
      {
        key: "purchases",
        count: this.stats.purchase_count ?? 0,
        label: i18n("discourse_cosmetics_store.history.tabs.purchases"),
      },
      {
        key: "gifts_sent",
        count: this.stats.gifts_sent_count ?? 0,
        label: i18n("discourse_cosmetics_store.history.tabs.gifts_sent"),
      },
      {
        key: "gifts_received",
        count: this.stats.gifts_received_count ?? 0,
        label: i18n("discourse_cosmetics_store.history.tabs.gifts_received"),
      },
    ];
  }

  get visibleEntries() {
    const rows = this.history[this.mode] ?? [];
    return rows.map((entry) => ({
      ...entry,
      date_label: this.formatDate(entry.created_at),
      status_label: i18n(
        `discourse_cosmetics_store.history.status.${entry.status || "completed"}`
      ),
      product_name:
        entry.product?.name ??
        i18n("discourse_cosmetics_store.history.unknown_product"),
    }));
  }

  get emptyTitle() {
    return i18n(`discourse_cosmetics_store.history.empty.${this.mode}_title`);
  }

  get emptyDescription() {
    return i18n(
      `discourse_cosmetics_store.history.empty.${this.mode}_description`
    );
  }

  get currentLimit() {
    return this.history.limits?.[this.mode] ?? 100;
  }

  get currentTotal() {
    if (this.mode === "gifts_sent") {
      return this.stats.gifts_sent_count ?? 0;
    }
    if (this.mode === "gifts_received") {
      return this.stats.gifts_received_count ?? 0;
    }
    return this.stats.purchase_count ?? 0;
  }

  get isTruncated() {
    return this.currentTotal > this.currentLimit;
  }

  formatDate(value) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "";
    }

    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(date);
  }

  @action
  setMode(mode) {
    if (["purchases", "gifts_sent", "gifts_received"].includes(mode)) {
      this.mode = mode;
    }
  }

  <template>
    <div class="cstore-shell" data-testid="cosmetics-history">
      {{#if @viewer.logged_in}}
        <main class="cstore-section cstore-favorites-page">
          <div class="cstore-section__heading">
            <div>
              <p class="cstore-eyebrow">
                {{i18n "discourse_cosmetics_store.history.eyebrow"}}
              </p>
              <h1>{{i18n "discourse_cosmetics_store.history.title"}}</h1>
              <span>{{i18n "discourse_cosmetics_store.history.subtitle"}}</span>
            </div>
            <div>
              <a class="btn btn-default" href="/store/inventory">
                {{i18n "discourse_cosmetics_store.nav.inventory"}}
              </a>
              <a class="btn btn-primary" href="/store">
                {{i18n "discourse_cosmetics_store.title"}}
              </a>
            </div>
          </div>

          <div class="cstore-wallet-stats">
            <span data-testid="history-purchase-count">
              <strong>{{this.stats.purchase_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.history.stats.purchases"}}</small>
            </span>
            <span data-testid="history-gifts-sent-count">
              <strong>{{this.stats.gifts_sent_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.history.stats.gifts_sent"}}</small>
            </span>
            <span data-testid="history-gifts-received-count">
              <strong>{{this.stats.gifts_received_count}}</strong>
              <small>{{i18n "discourse_cosmetics_store.history.stats.gifts_received"}}</small>
            </span>
          </div>

          <div class="cstore-results__bar">
            <div role="tablist" aria-label={{i18n "discourse_cosmetics_store.history.title"}}>
              {{#each this.tabs as |tab|}}
                <button
                  type="button"
                  role="tab"
                  aria-selected={{eq this.mode tab.key}}
                  class={{if (eq this.mode tab.key) "btn btn-primary" "btn btn-default"}}
                  data-testid="history-tab-{{tab.key}}"
                  {{on "click" (fn this.setMode tab.key)}}
                >
                  {{tab.label}} ({{tab.count}})
                </button>
              {{/each}}
            </div>
          </div>

          {{#if this.visibleEntries.length}}
            <div class="cstore-missions">
              {{#each this.visibleEntries as |entry|}}
                <article
                  class="cstore-mission {{if (eq entry.status 'refunded') 'is-claimed'}}"
                  data-testid="history-entry"
                >
                  <span class="cstore-mission__icon" aria-hidden="true">
                    {{#if (eq this.mode "purchases")}}
                      {{dIcon "cart-shopping"}}
                    {{else}}
                      {{dIcon "gift"}}
                    {{/if}}
                  </span>

                  <div>
                    <strong>{{entry.product_name}}</strong>
                    {{#if (eq this.mode "gifts_sent")}}
                      <p>
                        {{i18n
                          "discourse_cosmetics_store.history.sent_to"
                          username=entry.user.username
                        }}
                      </p>
                    {{else if (eq this.mode "gifts_received")}}
                      <p>
                        {{i18n
                          "discourse_cosmetics_store.history.received_from"
                          username=entry.user.username
                        }}
                      </p>
                    {{/if}}
                    <small>{{entry.date_label}} · {{entry.status_label}}</small>
                  </div>

                  <div class="cstore-mission__reward">
                    <b>{{entry.price_paid}} {{this.history.currency_symbol}}</b>
                    {{#if entry.user.path}}
                      <a class="btn btn-default btn-small" href={{entry.user.path}}>
                        {{i18n "discourse_cosmetics_store.history.profile_action"}}
                      </a>
                    {{/if}}
                  </div>
                </article>
              {{/each}}
            </div>

            {{#if this.isTruncated}}
              <p class="cstore-muted">
                {{i18n
                  "discourse_cosmetics_store.history.truncated"
                  limit=this.currentLimit
                  total=this.currentTotal
                }}
              </p>
            {{/if}}
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
            <strong>{{i18n "discourse_cosmetics_store.history.login_title"}}</strong>
            <p>{{i18n "discourse_cosmetics_store.history.login_description"}}</p>
            <a class="btn btn-primary" href="/login?return_path=%2Fstore%2Fhistory">
              {{i18n "discourse_cosmetics_store.history.login_action"}}
            </a>
          </section>
        </main>
      {{/if}}
    </div>
  </template>
}
