import CosmeticsStoreProductForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-product-form";

export default <template>
  <CosmeticsStoreProductForm
    @catalog={{@controller.model.catalog}}
    @product={{@controller.model.product}}
  />
</template>;
