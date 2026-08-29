import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreCollectionProgress from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-collection-progress";

module("Component | CosmeticsStoreCollectionProgress", function (hooks) {
  setupRenderingTest(hooks);

  test("renders ownership and current access as separate progress values", async function (assert) {
    this.model = {
      viewer: { logged_in: true },
      collections: [
        {
          slug: "night-set",
          name: "Night Set",
          item_count: 2,
          directly_owned_item_count: 1,
          unlocked_item_count: 2,
          directly_owned_complete: false,
          unlocked_complete: true,
        },
      ],
    };

    await render(
      <template>
        <CosmeticsStoreCollectionProgress @model={{this.model}} />
      </template>
    );

    assert.dom(".cstore-mission").exists({ count: 1 });
    assert.dom(".cstore-mission").hasTextContaining("Night Set");
    assert.dom(".cstore-mission").hasTextContaining("1 of 2 owned");
    assert.dom(".cstore-mission").hasTextContaining("All currently unlocked");
    assert.dom(".cstore-mission progress").exists({ count: 2 });
  });

  test("does not expose collection progress to anonymous viewers", async function (assert) {
    this.model = {
      viewer: { logged_in: false },
      collections: [
        {
          slug: "private-set",
          name: "Private Set",
          item_count: 1,
          directly_owned_item_count: 1,
          unlocked_item_count: 1,
          directly_owned_complete: true,
          unlocked_complete: true,
        },
      ],
    };

    await render(
      <template>
        <CosmeticsStoreCollectionProgress @model={{this.model}} />
      </template>
    );

    assert.dom(".cstore-mission").doesNotExist();
    assert.dom(".cstore-section").doesNotExist();
  });
});
