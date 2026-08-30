import CosmeticsStoreOrbPackageForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-orb-package-form";

export default <template>
  <CosmeticsStoreOrbPackageForm
    @catalog={{@controller.model.catalog}}
    @package={{@controller.model.package}}
  />
</template>;
