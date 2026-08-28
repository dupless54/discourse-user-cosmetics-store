import RouteTemplate from "ember-route-template";
import CosmeticsStoreAdminPage from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-admin-page";
import CosmeticsStoreAuditAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-audit-admin";
import CosmeticsStoreHealthAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-health-admin";

export default RouteTemplate(
  <template>
    <CosmeticsStoreHealthAdmin @health={{@controller.model.health}} />
    <CosmeticsStoreAuditAdmin @entries={{@controller.model.audit_log}} />
    <CosmeticsStoreAdminPage @model={{@controller.model}} />
  </template>
);
