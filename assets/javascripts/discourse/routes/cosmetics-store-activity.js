import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreActivityRoute extends CosmeticsStoreBaseRoute {
  storeTab = "activity";

  async model() {
    const payload = await ajax("/cosmetics-store/activity.json");

    return {
      ...payload,
      route_tab: this.storeTab,
    };
  }
}
