import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreInventoryRoute extends CosmeticsStoreBaseRoute {
  storeTab = "inventory";

  async model() {
    const payload = await ajax("/cosmetics-store/inventory.json");

    return {
      ...payload,
      route_tab: this.storeTab,
    };
  }
}
