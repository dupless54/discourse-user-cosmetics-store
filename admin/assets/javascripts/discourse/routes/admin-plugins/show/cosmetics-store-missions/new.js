import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const PARENT_ROUTE = "adminPlugins.show.cosmetics-store-missions";

export default class CosmeticsStoreMissionsNewRoute extends DiscourseRoute {
  model() {
    return { catalog: this.modelFor(PARENT_ROUTE), mission: null };
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.mission.add");
  }
}
