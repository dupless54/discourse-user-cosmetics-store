import { module, test } from "qunit";
import {
  availabilityBadge,
  availabilityDetail,
  availabilityMatches,
} from "discourse/plugins/discourse-user-cosmetics-store/discourse/lib/cosmetics-store-availability";

module("Unit | discourse-user-cosmetics-store | availability", function () {
  test("classifies badges for upcoming, seasonal, and limited products", function (assert) {
    assert.strictEqual(
      availabilityBadge({ sale_state: "upcoming", availability_type: "seasonal" }),
      "COMING SOON"
    );
    assert.strictEqual(
      availabilityBadge({ sale_state: "active", availability_type: "seasonal" }),
      "SEASONAL"
    );
    assert.strictEqual(
      availabilityBadge({ sale_state: "active", availability_type: "limited" }),
      "LIMITED TIME"
    );
    assert.strictEqual(
      availabilityBadge({ sale_state: "active", availability_type: "standard" }),
      null
    );
  });

  test("formats deterministic remaining-time copy through client i18n", function (assert) {
    const now = Date.parse("2026-08-29T09:00:00Z");

    assert.strictEqual(
      availabilityDetail(
        {
          sale_state: "upcoming",
          available_from: "2026-08-30T11:30:00Z",
        },
        now
      ),
      "Opens in 1d 2h"
    );
    assert.strictEqual(
      availabilityDetail(
        {
          sale_state: "active",
          available_until: "2026-08-29T10:15:00Z",
        },
        now
      ),
      "1h 15m left"
    );
  });

  test("matches availability filters without treating upcoming as active seasonal", function (assert) {
    const upcoming = { sale_state: "upcoming", availability_type: "seasonal" };
    const limited = { sale_state: "active", availability_type: "limited" };

    assert.true(availabilityMatches(upcoming, "upcoming"));
    assert.true(availabilityMatches(upcoming, "seasonal"));
    assert.false(availabilityMatches(upcoming, "limited"));
    assert.true(availabilityMatches(limited, "limited"));
    assert.true(availabilityMatches(limited, ""));
  });
});
