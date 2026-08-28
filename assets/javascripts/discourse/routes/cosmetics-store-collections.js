import { ajax } from "discourse/lib/ajax";
import CosmeticsStoreBaseRoute from "./cosmetics-store-base";

export default class CosmeticsStoreCollectionsRoute extends CosmeticsStoreBaseRoute {
  storeTab = "collections";

  async model(params = {}) {
    const [store, progress] = await Promise.all([
      super.model(params),
      ajax("/cosmetics-store/inventory.json?scope=collections"),
    ]);
    const progressBySlug = new Map(
      (progress.collections || []).map((collection) => [collection.slug, collection])
    );

    return {
      ...store,
      collections: (store.collections || []).map((collection) => ({
        ...collection,
        ...(progressBySlug.get(collection.slug) || {}),
      })),
    };
  }
}
