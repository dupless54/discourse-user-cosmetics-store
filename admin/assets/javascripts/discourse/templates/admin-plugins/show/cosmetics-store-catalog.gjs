import RouteTemplate from "ember-route-template";
import CosmeticsStoreAdminPage from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-admin-page";

export default RouteTemplate(
  <template>
    <CosmeticsStoreAdminPage @model={{@controller.model}} />
  </template>
);
