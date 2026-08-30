import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStorePreview from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-preview";

module("Component | cosmetics store preview i18n", function (hooks) {
  setupRenderingTest(hooks);

  test("renders fallback preview copy from Discourse client i18n", async function (assert) {
    this.product = {
      product_type: "bundle",
      item_count: 2,
      items: [
        {
          id: 1,
          name: "Aurora nameplate",
          kind: "nameplate",
          image_url: null,
        },
        {
          id: 2,
          name: "Aurora card",
          kind: "card_decoration",
          image_url: null,
        },
      ],
    };
    this.previewUser = {};

    await render(
      <template>
        <CosmeticsStorePreview
          @product={{this.product}}
          @previewUser={{this.previewUser}}
        />
      </template>
    );

    assert.dom(".cstore-preview__nameplate").includesText("Community member");
    assert.dom(".cstore-preview__card").includesText("User card");
    assert.dom(".cstore-preview__count").hasText("2 items");
  });
});
