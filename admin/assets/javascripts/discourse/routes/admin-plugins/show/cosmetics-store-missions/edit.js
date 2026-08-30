import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const PARENT_ROUTE = "adminPlugins.show.cosmetics-store-missions";

export default class CosmeticsStoreMissionsEditRoute extends DiscourseRoute {
  model(params) {
    const catalog = this.modelFor(PARENT_ROUTE);
    const id = Number.parseInt(params.id, 10);
    const mission = catalog.missions.find((item) => item.id === id);

    if (!mission) {
      this.replaceWith(PARENT_ROUTE);
      return;
    }

    return { catalog, mission };
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.mission.edit");
  }
}
