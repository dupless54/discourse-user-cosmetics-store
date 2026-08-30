import { module, test } from "qunit";
import { cosmeticsStoreAvatarFrameScale } from "discourse/plugins/discourse-user-cosmetics-store/discourse/initializers/cosmetics-store-avatar-frame-scale";

module("Unit | cosmetics store avatar frame scale", function () {
  test("matches the Base plugin overhang contract", function (assert) {
    assert.strictEqual(cosmeticsStoreAvatarFrameScale(0), 1);
    assert.strictEqual(cosmeticsStoreAvatarFrameScale(14), 1.28);
    assert.strictEqual(cosmeticsStoreAvatarFrameScale(25), 1.5);
  });

  test("clamps invalid values to the supported Base plugin range", function (assert) {
    assert.strictEqual(cosmeticsStoreAvatarFrameScale(-20), 1);
    assert.strictEqual(cosmeticsStoreAvatarFrameScale(100), 2.2);
    assert.strictEqual(cosmeticsStoreAvatarFrameScale("invalid"), 1.28);
  });
});
