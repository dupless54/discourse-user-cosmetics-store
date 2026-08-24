import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

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
    return "Cosmetics Store";
  }

  activate() {
    document.body.classList.add("cosmetics-store-route");
  }

  deactivate() {
    document.body.classList.remove("cosmetics-store-route");
  }
}
