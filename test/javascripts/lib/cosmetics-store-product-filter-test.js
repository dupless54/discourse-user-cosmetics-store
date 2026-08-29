import { module, test } from "qunit";
import {
  activeProductFilterCount,
  filterAndSortProducts,
  productMatchesFilters,
} from "discourse/plugins/discourse-user-cosmetics-store/discourse/lib/cosmetics-store-product-filter";

module("Unit | cosmetics store product filter", function () {
  const products = [
    {
      id: 1,
      name: "Gold Frame",
      description: "Bright frame",
      favorite: true,
      favoriteable: true,
      kinds: ["avatar_frame"],
      rarity_label: "Legendary",
      availability_type: "limited",
      sale_state: "active",
      tags: ["gold"],
      product_type: "item",
      price: 80,
      owned: false,
      popularity_score: 20,
      sort_order: 2,
      created_at: "2026-08-01T00:00:00Z",
      items: [{ name: "Gold Ring" }],
    },
    {
      id: 2,
      name: "Night Bundle",
      description: "Dark collection",
      favorite: true,
      favoriteable: false,
      kinds: ["nameplate", "profile_effect"],
      rarity_label: "Epic",
      availability_type: "seasonal",
      sale_state: "upcoming",
      tags: ["night"],
      product_type: "bundle",
      price: 35,
      owned: true,
      popularity_score: 50,
      sort_order: 1,
      created_at: "2026-08-20T00:00:00Z",
      items: [{ name: "Night Plate" }],
    },
    {
      id: 3,
      name: "Blue Frame",
      description: "Not saved",
      favorite: false,
      favoriteable: true,
      kinds: ["avatar_frame"],
      rarity_label: "Rare",
      availability_type: "standard",
      sale_state: "active",
      tags: ["blue"],
      product_type: "item",
      price: 10,
      owned: false,
      popularity_score: 100,
      sort_order: 0,
      created_at: "2026-08-25T00:00:00Z",
      items: [],
    },
  ];

  test("combines favorite, search, catalog, affordability, and ownership filters", function (assert) {
    assert.true(
      productMatchesFilters(products[1], {
        favoriteOnly: true,
        search: "night plate",
        kind: "profile_effect",
        rarity: "Epic",
        availability: "upcoming",
        tag: "night",
        productType: "bundle",
        onlyAffordable: true,
        onlyOwned: true,
        balance: 40,
      })
    );

    assert.false(
      productMatchesFilters(products[0], {
        favoriteOnly: true,
        onlyAffordable: true,
        balance: 40,
      })
    );
    assert.false(
      productMatchesFilters(products[2], { favoriteOnly: true }),
      "non-favorites never enter the favorites result set"
    );
  });

  test("sorts only the filtered favorite set", function (assert) {
    assert.deepEqual(
      filterAndSortProducts(products, {
        favoriteOnly: true,
        sortBy: "price-low",
      }).map((product) => product.id),
      [2, 1]
    );

    assert.deepEqual(
      filterAndSortProducts(products, {
        favoriteOnly: true,
        sortBy: "popular",
      }).map((product) => product.id),
      [2, 1]
    );
  });

  test("counts only user-visible filter criteria", function (assert) {
    assert.strictEqual(
      activeProductFilterCount({
        favoriteOnly: true,
        search: "night",
        rarity: "Epic",
        sortBy: "newest",
        onlyOwned: true,
      }),
      3,
      "favorite scope and sorting do not inflate active-filter count"
    );
  });
});
