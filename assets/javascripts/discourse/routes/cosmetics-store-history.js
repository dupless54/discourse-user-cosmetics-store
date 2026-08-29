import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreHistoryRoute extends CosmeticsStoreBaseRoute {
  redirect() {
    this.replaceWith("cosmetics-store-activity");
  }
}
