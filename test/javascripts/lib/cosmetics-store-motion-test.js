import { module, test } from "qunit";
import { prefersReducedMotion } from "discourse/plugins/discourse-user-cosmetics-store/discourse/lib/cosmetics-store-motion";

module("Unit | discourse-user-cosmetics-store | motion", function (hooks) {
  let originalMatchMedia;

  hooks.beforeEach(function () {
    originalMatchMedia = window.matchMedia;
  });

  hooks.afterEach(function () {
    window.matchMedia = originalMatchMedia;
  });

  test("reads the operating-system reduced motion preference", function (assert) {
    window.matchMedia = (query) => ({
      matches: query === "(prefers-reduced-motion: reduce)",
    });

    assert.true(prefersReducedMotion());

    window.matchMedia = () => ({ matches: false });
    assert.false(prefersReducedMotion());
  });
});
