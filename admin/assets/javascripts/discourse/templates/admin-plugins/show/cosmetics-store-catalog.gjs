import RouteTemplate from "ember-route-template";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import CosmeticsStoreAuditAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-audit-admin";
import CosmeticsStoreHealthAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-health-admin";

export default RouteTemplate(
  <template>
    <div class="admin-config-page__main-area">
      <DPageSubheader
        @titleLabel={{i18n "discourse_cosmetics_store.admin.overview"}}
        @descriptionLabel={{i18n "discourse_cosmetics_store.admin.overview_description"}}
      >
        <:actions as |actions|>
          <actions.Wrapped>
            <a
              class="btn btn-default d-page-action-button"
              href="/store"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{i18n "discourse_cosmetics_store.admin.open_store"}}
            </a>
          </actions.Wrapped>
        </:actions>
      </DPageSubheader>

      <CosmeticsStoreHealthAdmin @health={{@controller.model.health}} />
      <CosmeticsStoreAuditAdmin @entries={{@controller.model.audit_log}} />
    </div>
  </template>
);
