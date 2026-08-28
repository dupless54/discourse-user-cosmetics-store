import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class CosmeticsStoreCollectionProgress extends Component {
  get collections() {
    if (!this.args.model?.viewer?.logged_in) {
      return [];
    }

    const rows = (this.args.model?.collections ?? []).filter(
      (collection) => collection.item_count > 0
    );
    const slug = this.args.model?.collection_slug;

    if (!slug) {
      return rows;
    }

    return rows.filter((collection) => collection.slug === slug);
  }

  ownedLabel(collection) {
    if (collection.directly_owned_complete) {
      return i18n("discourse_cosmetics_store.collections.owned_complete");
    }

    return i18n("discourse_cosmetics_store.collections.owned_progress", {
      owned: collection.directly_owned_item_count,
      total: collection.item_count,
    });
  }

  unlockedLabel(collection) {
    if (collection.unlocked_complete) {
      return i18n("discourse_cosmetics_store.collections.unlocked_complete");
    }

    return i18n("discourse_cosmetics_store.collections.unlocked_progress", {
      unlocked: collection.unlocked_item_count,
      total: collection.item_count,
    });
  }

  <template>
    {{#if this.collections.length}}
      <section class="cstore-section">
        <div class="cstore-section__heading">
          <div>
            <p class="cstore-eyebrow">
              {{i18n "discourse_cosmetics_store.collections.progress_eyebrow"}}
            </p>
            <h2>{{i18n "discourse_cosmetics_store.collections.progress_title"}}</h2>
            <span>{{i18n "discourse_cosmetics_store.collections.progress_subtitle"}}</span>
          </div>
          <a class="btn btn-default" href="/store/inventory">
            {{i18n "discourse_cosmetics_store.nav.inventory"}}
          </a>
        </div>

        <div class="cstore-missions">
          {{#each this.collections as |collection|}}
            <article class="cstore-mission">
              <div>
                <strong>{{collection.name}}</strong>
                <p>{{this.ownedLabel collection}}</p>
                <progress
                  class="cstore-progress"
                  value={{collection.directly_owned_item_count}}
                  max={{collection.item_count}}
                ></progress>
                <small>{{collection.directly_owned_item_count}} / {{collection.item_count}}</small>
              </div>
              <div>
                <p>{{this.unlockedLabel collection}}</p>
                <progress
                  class="cstore-progress"
                  value={{collection.unlocked_item_count}}
                  max={{collection.item_count}}
                ></progress>
                <small>{{collection.unlocked_item_count}} / {{collection.item_count}}</small>
              </div>
            </article>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
