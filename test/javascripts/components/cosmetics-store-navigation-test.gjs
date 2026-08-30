import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStore from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store";

module("Component | cosmetics store navigation", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.storeModel = {
      route_tab: "featured",
      route_filter: null,
      products: [],
      missions: [],
      filters: {
        kinds: [],
        rarities: [],
        availability: [],
        tags: [],
      },
      sections: {},
      settings: {
        currency_symbol: "◈",
        hover_preview: false,
      },
      wallet: {
        balance: 3744,
        debt: 0,
        lifetime_earned: 0,
        lifetime_spent: 0,
        ledger: [],
      },
      viewer: {
        logged_in: true,
        favorites_enabled: true,
        preview_user: {},
      },
      orb_packages: [],
      payment_providers: [],
      payments: [],
      collections: [],
    };
  });

  test("browse disclosure remains usable without hover", async function (assert) {
    await render(<template><CosmeticsStore @model={{this.storeModel}} /></template>);

    assert.dom(".cstore-nav").exists();
    assert.dom(".cstore-balance").hasText("◈3744");
    assert
      .dom(".cstore-nav__browse-menu > button")
      .hasAttribute("aria-expanded", "false");
    assert.dom(".cstore-nav__browse-menu").doesNotHaveClass("is-open");

    await click(".cstore-nav__browse-menu > button");

    assert
      .dom(".cstore-nav__browse-menu > button")
      .hasAttribute("aria-expanded", "true");
    assert.dom(".cstore-nav__browse-menu").hasClass("is-open");

    await click(".cstore-nav__browse-menu > button");

    assert
      .dom(".cstore-nav__browse-menu > button")
      .hasAttribute("aria-expanded", "false");
    assert.dom(".cstore-nav__browse-menu").doesNotHaveClass("is-open");
  });
});
