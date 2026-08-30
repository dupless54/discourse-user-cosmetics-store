import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import CosmeticsStoreMissionsAdmin from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-missions-admin";

const NEW_ROUTE = "adminPlugins.show.cosmetics-store-missions.new";

export default <template>
  <div class="admin-config-page__main-area">
    <DPageSubheader
      @titleLabel={{i18n "discourse_cosmetics_store.admin.missions"}}
      @descriptionLabel={{i18n "discourse_cosmetics_store.admin.missions_description"}}
    >
      <:actions as |actions|>
        <actions.Wrapped>
          <DButton
            class="btn-primary"
            @route={{NEW_ROUTE}}
            @icon="plus"
            @label="discourse_cosmetics_store.admin.mission.add"
          />
        </actions.Wrapped>
      </:actions>
    </DPageSubheader>

    <CosmeticsStoreMissionsAdmin @model={{@controller.model}} />
  </div>
</template>;
