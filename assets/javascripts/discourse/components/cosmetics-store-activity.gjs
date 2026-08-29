import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const EMPTY_ACTIVITY = {
  events: [],
  stats: {
    purchases: 0,
    gifts_sent: 0,
    gifts_received: 0,
    orb_events: 0,
  },
  wallet: {
    balance: 0,
    debt: 0,
    lifetime_earned: 0,
    lifetime_spent: 0,
  },
};

export default class CosmeticsStoreActivity extends Component {
  @tracked filter = "all";

  get activity() {
    return this.args.activity ?? EMPTY_ACTIVITY;
  }

  get stats() {
    return this.activity.stats ?? EMPTY_ACTIVITY.stats;
  }

  get wallet() {
    return this.activity.wallet ?? EMPTY_ACTIVITY.wallet;
  }

  get visibleEvents() {
    return (this.activity.events ?? [])
      .filter((event) => {
        if (this.filter === "all") {
          return true;
        }
        if (this.filter === "gifts") {
          return event.kind === "gift_sent" || event.kind === "gift_received";
        }
        return event.kind === this.filter;
      })
      .map((event) => ({
        ...event,
        title: this.eventTitle(event),
        icon: this.eventIcon(event),
        date_label: this.formatTimestamp(event.created_at),
        amount_label:
          event.amount === null || event.amount === undefined
            ? null
            : this.formatAmount(event.amount),
        amount_class: this.amountClass(event.amount),
      }));
  }

  @action
  setFilter(filter) {
    if (["all", "purchase", "gifts", "orb"].includes(filter)) {
      this.filter = filter;
    }
  }

  eventIcon(event) {
    switch (event.kind) {
      case "purchase":
        return "cart-shopping";
      case "gift_sent":
        return "paper-plane";
      case "gift_received":
        return "gift";
      default:
        return "clock";
    }
  }

  eventTitle(event) {
    switch (event.kind) {
      case "purchase":
        return i18n("discourse_cosmetics_store.activity.events.purchase", {
          name: event.product?.name ?? "",
        });
      case "gift_sent":
        return i18n("discourse_cosmetics_store.activity.events.gift_sent", {
          name: event.product?.name ?? "",
          username: event.counterparty?.username ?? "",
        });
      case "gift_received":
        return i18n("discourse_cosmetics_store.activity.events.gift_received", {
          name: event.product?.name ?? "",
          username: event.counterparty?.username ?? "",
        });
      default:
        return i18n(
          `discourse_cosmetics_store.activity.events.orb.${event.entry_type}`
        );
    }
  }

  amountClass(amount) {
    const value = Number(amount);
    if (value > 0) {
      return "is-positive";
    }
    if (value < 0) {
      return "is-negative";
    }
    return "";
  }

  formatAmount(amount) {
    const value = Number(amount) || 0;
    return `${value > 0 ? "+" : ""}${value}`;
  }

  formatTimestamp(value) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "";
    }

    return new Intl.DateTimeFormat(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(date);
  }

  <template>
    <div class="cstore-shell" data-testid="cosmetics-store-activity">
      {{#if @viewer.logged_in}}
        <main class="cstore-section cstore-activity">
          <div class="cstore-section__heading cstore-activity__heading">
            <div>
              <p class="cstore-eyebrow">
                {{i18n "discourse_cosmetics_store.activity.eyebrow"}}
              </p>
              <h1>{{i18n "discourse_cosmetics_store.activity.title"}}</h1>
              <span>{{i18n "discourse_cosmetics_store.activity.subtitle"}}</span>
            </div>
            <div>
              <a class="btn btn-default" href="/store">
                {{i18n "discourse_cosmetics_store.title"}}
              </a>
              <a class="btn btn-default" href="/store/inventory">
                {{dIcon "image"}}
                {{i18n "discourse_cosmetics_store.nav.inventory"}}
              </a>
            </div>
          </div>

          <section class="cstore-activity__wallet" aria-label={{i18n "discourse_cosmetics_store.activity.wallet_label"}}>
            <div>
              <span>{{i18n "discourse_cosmetics_store.activity.balance"}}</span>
              <strong data-testid="activity-balance">{{this.wallet.balance}}</strong>
            </div>
            <div>
              <span>{{i18n "discourse_cosmetics_store.activity.lifetime_earned"}}</span>
              <strong>{{this.wallet.lifetime_earned}}</strong>
            </div>
            <div>
              <span>{{i18n "discourse_cosmetics_store.activity.lifetime_spent"}}</span>
              <strong>{{this.wallet.lifetime_spent}}</strong>
            </div>
            {{#if this.wallet.debt}}
              <div class="is-debt">
                <span>{{i18n "discourse_cosmetics_store.activity.refund_debt"}}</span>
                <strong>{{this.wallet.debt}}</strong>
              </div>
            {{/if}}
          </section>

          <section class="cstore-activity__stats">
            <span><strong>{{this.stats.purchases}}</strong>{{i18n "discourse_cosmetics_store.activity.stats.purchases"}}</span>
            <span><strong>{{this.stats.gifts_sent}}</strong>{{i18n "discourse_cosmetics_store.activity.stats.gifts_sent"}}</span>
            <span><strong>{{this.stats.gifts_received}}</strong>{{i18n "discourse_cosmetics_store.activity.stats.gifts_received"}}</span>
            <span><strong>{{this.stats.orb_events}}</strong>{{i18n "discourse_cosmetics_store.activity.stats.orb_events"}}</span>
          </section>

          <div class="cstore-activity__filters" role="group" aria-label={{i18n "discourse_cosmetics_store.activity.filters.label"}}>
            <button
              type="button"
              class={{if (eq this.filter "all") "btn btn-primary" "btn btn-default"}}
              aria-pressed={{eq this.filter "all"}}
              data-testid="activity-filter-all"
              {{on "click" (fn this.setFilter "all")}}
            >
              {{i18n "discourse_cosmetics_store.activity.filters.all"}}
            </button>
            <button
              type="button"
              class={{if (eq this.filter "purchase") "btn btn-primary" "btn btn-default"}}
              aria-pressed={{eq this.filter "purchase"}}
              data-testid="activity-filter-purchase"
              {{on "click" (fn this.setFilter "purchase")}}
            >
              {{i18n "discourse_cosmetics_store.activity.filters.purchase"}}
            </button>
            <button
              type="button"
              class={{if (eq this.filter "gifts") "btn btn-primary" "btn btn-default"}}
              aria-pressed={{eq this.filter "gifts"}}
              data-testid="activity-filter-gifts"
              {{on "click" (fn this.setFilter "gifts")}}
            >
              {{i18n "discourse_cosmetics_store.activity.filters.gifts"}}
            </button>
            <button
              type="button"
              class={{if (eq this.filter "orb") "btn btn-primary" "btn btn-default"}}
              aria-pressed={{eq this.filter "orb"}}
              data-testid="activity-filter-orb"
              {{on "click" (fn this.setFilter "orb")}}
            >
              {{i18n "discourse_cosmetics_store.activity.filters.orb"}}
            </button>
          </div>

          {{#if this.visibleEvents.length}}
            <div class="cstore-activity__timeline">
              {{#each this.visibleEvents as |event|}}
                <article class="cstore-activity__event" data-event-kind={{event.kind}}>
                  <span class="cstore-activity__icon" aria-hidden="true">
                    {{dIcon event.icon}}
                  </span>

                  <div class="cstore-activity__event-body">
                    <div class="cstore-activity__event-title">
                      <strong>{{event.title}}</strong>
                      {{#if (eq event.status "refunded")}}
                        <span class="cstore-activity__status">
                          {{i18n "discourse_cosmetics_store.activity.refunded"}}
                        </span>
                      {{/if}}
                    </div>

                    <time datetime={{event.created_at}}>{{event.date_label}}</time>

                    {{#if event.product}}
                      <div class="cstore-activity__product">
                        {{#if event.product.card_image_url}}
                          <img src={{event.product.card_image_url}} alt="" loading="lazy" />
                        {{/if}}
                        <span>
                          {{#if event.product.rarity_label}}
                            <i>{{event.product.rarity_label}}</i>
                          {{/if}}
                          {{#if event.product.collection_name}}
                            <small>{{event.product.collection_name}}</small>
                          {{/if}}
                        </span>
                      </div>
                    {{/if}}
                  </div>

                  {{#if event.amount_label}}
                    <strong class="cstore-activity__amount {{event.amount_class}}">
                      {{event.amount_label}}
                    </strong>
                  {{/if}}
                </article>
              {{/each}}
            </div>
          {{else}}
            <section class="cstore-empty" data-testid="activity-empty">
              <strong>{{i18n "discourse_cosmetics_store.activity.empty_title"}}</strong>
              <p>{{i18n "discourse_cosmetics_store.activity.empty_description"}}</p>
            </section>
          {{/if}}
        </main>
      {{else}}
        <main class="cstore-section cstore-favorites-page">
          <section class="cstore-empty">
            <strong>{{i18n "discourse_cosmetics_store.activity.login_title"}}</strong>
            <p>{{i18n "discourse_cosmetics_store.activity.login_description"}}</p>
            <a class="btn btn-primary" href="/login?return_path=%2Fstore%2Factivity">
              {{i18n "discourse_cosmetics_store.activity.login_action"}}
            </a>
          </section>
        </main>
      {{/if}}
    </div>
  </template>
}
