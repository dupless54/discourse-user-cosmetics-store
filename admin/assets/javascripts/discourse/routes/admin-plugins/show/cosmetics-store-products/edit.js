import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const PARENT_ROUTE = "adminPlugins.show.cosmetics-store-products";

export default class CosmeticsStoreProductsEditRoute extends DiscourseRoute {
  model(params) {
    const catalog = this.modelFor(PARENT_ROUTE);
    const id = Number.parseInt(params.id, 10);
    return {
      catalog,
      product: catalog.products.find((product) => product.id === id),
    };
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.product.edit");
  }
}
