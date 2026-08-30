import RouteTemplate from "ember-route-template";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import CosmeticsStoreProductsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-products-admin";

export default RouteTemplate(
  <template>
    <div class="admin-config-page__main-area">
      <DPageSubheader
        @titleLabel={{i18n "discourse_cosmetics_store.admin.products"}}
        @descriptionLabel={{i18n "discourse_cosmetics_store.admin.products_description"}}
      />
      <CosmeticsStoreProductsAdmin @model={{@controller.model}} />
    </div>
  </template>
);
