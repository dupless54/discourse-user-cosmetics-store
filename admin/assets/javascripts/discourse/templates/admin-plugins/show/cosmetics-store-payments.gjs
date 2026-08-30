import RouteTemplate from "ember-route-template";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import CosmeticsStorePaymentsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-payments-admin";

export default RouteTemplate(
  <template>
    <div class="admin-config-page__main-area">
      <DPageSubheader
        @titleLabel={{i18n "discourse_cosmetics_store.admin.payments"}}
        @descriptionLabel={{i18n "discourse_cosmetics_store.admin.payments_description"}}
      />
      <CosmeticsStorePaymentsAdmin
        @packages={{@controller.model.orb_packages}}
        @providers={{@controller.model.payment_providers}}
        @payments={{@controller.model.payments}}
      />
    </div>
  </template>
);
