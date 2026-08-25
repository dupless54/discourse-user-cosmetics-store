import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CosmeticsStoreBaseRoute extends DiscourseRoute {
  storeTab = "featured";

  model(params = {}) {
    return ajax("/cosmetics-store.json").then((model) => ({
      ...model,
      route_tab: this.storeTab,
      route_filter: params.category || "",
      collection_slug: params.collection_slug || "",
    }));
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.title");
  }

  activate() {
    document.body.classList.add("cosmetics-store-route");
  }

  deactivate() {
    document.body.classList.remove("cosmetics-store-route");
  }
}
