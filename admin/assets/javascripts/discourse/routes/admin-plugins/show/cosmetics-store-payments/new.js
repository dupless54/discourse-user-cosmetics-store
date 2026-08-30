import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const PARENT_ROUTE = "adminPlugins.show.cosmetics-store-payments";

export default class CosmeticsStorePaymentsNewRoute extends DiscourseRoute {
  model() {
    return { catalog: this.modelFor(PARENT_ROUTE), package: null };
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.orb_package.add");
  }
}
