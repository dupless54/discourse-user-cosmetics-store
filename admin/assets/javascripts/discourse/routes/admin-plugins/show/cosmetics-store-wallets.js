import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class CosmeticsStoreWalletsRoute extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/user-cosmetics-store/catalog.json");
  }

  titleToken() {
    return i18n("discourse_cosmetics_store.admin.wallets");
  }
}
