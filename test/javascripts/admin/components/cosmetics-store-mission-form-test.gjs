import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStoreMissionForm from "discourse/plugins/discourse-user-cosmetics-store/admin/components/cosmetics-store-mission-form";

module("Component | CosmeticsStoreMissionForm", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.catalog = {
      missions: [],
      mission_metrics: [
        { value: "posts_created", label: "Posts created" },
        { value: "likes_received", label: "Likes received" },
      ],
    };
  });

  test("renders the native FormKit mission editor", async function (assert) {
    await render(
      <template>
        <CosmeticsStoreMissionForm @catalog={{this.catalog}} @mission={{null}} />
      </template>
    );

    assert.dom('input[name="name"]').exists();
    assert.dom('input[name="key"]').exists();
    assert.dom('select[name="metric"]').exists();
    assert.dom('select[name="metric"] option').exists({ count: 2 });
    assert.dom('input[name="target"]').exists();
    assert.dom('input[name="reward"]').exists();
    assert.dom('textarea[name="description"]').exists();
    assert.dom(".cstore-admin-form--mission").doesNotExist();
  });
});
