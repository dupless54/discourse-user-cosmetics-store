import RouteTemplate from "ember-route-template";
import CosmeticsStoreAdminPage from "../../components/cosmetics-store-admin-page";

export default RouteTemplate(
  <template><CosmeticsStoreAdminPage @model={{@model}} /></template>
);
