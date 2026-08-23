import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsUserCosmeticsStoreRoute extends Route {
  model() {
    return ajax("/admin/plugins/user-cosmetics-store/catalog.json");
  }
}
