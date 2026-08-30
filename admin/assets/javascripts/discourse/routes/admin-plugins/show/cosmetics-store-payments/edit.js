import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const PARENT_ROUTE = "adminPlugins.show.cosmetics-store-payments";

export default class CosmeticsStorePaymentsEditRoute extends DiscourseRoute {
  model(params) {
    const catalog = this.modelFor(PARENT_ROUTE);
    const id = Number.parseInt(params.id, 10);
    const packageRow = catalog.orb_packages.find((item) => item.id === id);

    if (!packageRow) {
      this.replaceWith(PARENT_ROUTE);
      return;
    }

    return { catalog, package: packageRow };
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.orb_package.edit");
  }
}
