import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import CosmeticsStorePaymentsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-payments-admin";

const NEW_ROUTE = "adminPlugins.show.cosmetics-store-payments.new";

export default <template>
  <div class="admin-config-page__main-area">
    <DPageSubheader
      @titleLabel={{i18n "discourse_cosmetics_store.admin.payments"}}
      @descriptionLabel={{i18n "discourse_cosmetics_store.admin.payments_description"}}
    >
      <:actions as |actions|>
        <actions.Wrapped>
          <DButton
            class="btn-primary"
            @route={{NEW_ROUTE}}
            @icon="plus"
            @label="discourse_cosmetics_store.admin.orb_package.add"
          />
        </actions.Wrapped>
      </:actions>
    </DPageSubheader>

    <CosmeticsStorePaymentsAdmin @model={{@controller.model}} />
  </div>
</template>;
