import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreInventoryRoute extends CosmeticsStoreBaseRoute {
  storeTab = "inventory";

  async model(params = {}) {
    const [store, inventory] = await Promise.all([
      super.model(params),
      ajax("/cosmetics-store/inventory.json"),
    ]);

    return {
      ...store,
      inventory: inventory.inventory,
      inventory_collections: inventory.collections,
    };
  }
}
