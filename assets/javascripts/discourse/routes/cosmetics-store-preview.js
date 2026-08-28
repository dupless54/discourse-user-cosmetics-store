import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStorePreviewRoute extends CosmeticsStoreBaseRoute {
  storeTab = "preview";

  async model() {
    const payload = await ajax("/cosmetics-store/preview.json");

    return {
      ...payload,
      route_tab: this.storeTab,
    };
  }
}
