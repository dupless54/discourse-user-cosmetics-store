import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStorePreview from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-preview";
import CosmeticsStoreProfileEffectLayers from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-profile-effect-layers";

module("Component | Cosmetics Store reduced motion", function (hooks) {
  setupRenderingTest(hooks);

  let originalMatchMedia;

  hooks.beforeEach(function () {
    originalMatchMedia = window.matchMedia;
    window.matchMedia = (query) => ({
      matches: query === "(prefers-reduced-motion: reduce)",
    });
  });

  hooks.afterEach(function () {
    window.matchMedia = originalMatchMedia;
  });

  test("does not render profile-effect layers when reduced motion is requested", async function (assert) {
    this.effect = {
      layers: [
        {
          image_url: "/effect-front.gif",
          anchor: "full",
          stack_order: "front",
        },
      ],
    };

    await render(
      <template>
        <CosmeticsStoreProfileEffectLayers
          @effect={{this.effect}}
          @stackOrder="front"
        />
      </template>
    );

    assert.dom(".cstore-profile-effect-layers").doesNotExist();
    assert.dom(".cstore-profile-effect-layers__image").doesNotExist();
  });

  test("keeps the product preview static for motion-heavy cosmetic kinds", async function (assert) {
    this.product = {
      product_type: "bundle",
      item_count: 2,
      items: [
        {
          id: 1,
          name: "Animated card",
          kind: "card_decoration",
          image_url: "/card.gif",
        },
        {
          id: 2,
          name: "Animated effect",
          kind: "profile_effect",
          image_url: "/effect.gif",
          layers: [],
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

    assert.dom(".cstore-preview__card img").doesNotExist();
    assert.dom(".cstore-preview__effect-legacy").doesNotExist();
    assert.dom(".cstore-preview__effect-card").exists();
  });
});
