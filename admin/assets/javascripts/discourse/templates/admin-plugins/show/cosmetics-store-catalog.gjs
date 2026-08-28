import RouteTemplate from "ember-route-template";
import CosmeticsStoreAdminPage from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-admin-page";
import CosmeticsStoreHealthAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-health-admin";

export default RouteTemplate(
  <template>
    <CosmeticsStoreHealthAdmin @health={{@controller.model.health}} />
    <CosmeticsStoreAdminPage @model={{@controller.model}} />
  </template>
);
