import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreLoadoutsRoute extends CosmeticsStoreBaseRoute {
  storeTab = "loadouts";

  async model() {
    const payload = await ajax("/cosmetics-store/loadouts.json");

    return {
      ...payload,
      route_tab: this.storeTab,
    };
  }
}
