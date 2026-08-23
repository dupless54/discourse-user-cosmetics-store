import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class CosmeticsStoreRoute extends DiscourseRoute {
  model() {
    return ajax("/cosmetics-store.json");
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
