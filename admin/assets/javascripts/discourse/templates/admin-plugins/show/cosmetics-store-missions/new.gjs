import CosmeticsStoreMissionForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-mission-form";

export default <template>
  <CosmeticsStoreMissionForm
    @catalog={{@controller.model.catalog}}
    @mission={{@controller.model.mission}}
  />
</template>;
