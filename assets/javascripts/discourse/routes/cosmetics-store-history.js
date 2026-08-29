import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreHistoryRoute extends CosmeticsStoreBaseRoute {
  storeTab = "history";

  async model() {
    const payload = await ajax("/cosmetics-store/history.json");

    return {
      ...payload,
      route_tab: this.storeTab,
    };
  }
}
