import { availabilityMatches } from "./cosmetics-store-availability";

function normalizedText(value) {
  return String(value ?? "")
    .trim()
    .toLocaleLowerCase("tr-TR");
}

function searchableText(product) {
  return [
    product.name,
    product.description,
    ...(product.tags || []),
    ...(product.items || []).map((item) => item.name),
  ]
    .join(" ")
    .toLocaleLowerCase("tr-TR");
}

export function productMatchesFilters(product, filters = {}) {
  const query = normalizedText(filters.search);

  if (filters.favoriteOnly && !product.favorite) {
    return false;
  }
  if (query && !searchableText(product).includes(query)) {
    return false;
  }
  if (filters.kind && !(product.kinds || []).includes(filters.kind)) {
    return false;
  }
  if (filters.rarity && product.rarity_label !== filters.rarity) {
    return false;
  }
  if (filters.availability && !availabilityMatches(product, filters.availability)) {
    return false;
  }
  if (filters.tag && !(product.tags || []).includes(filters.tag)) {
    return false;
  }
  if (filters.productType && product.product_type !== filters.productType) {
    return false;
  }
  if (filters.onlyAffordable && Number(product.price) > Number(filters.balance || 0)) {
    return false;
  }
  if (filters.onlyOwned && !product.owned) {
    return false;
  }

  return true;
}

export function filterAndSortProducts(products, filters = {}) {
  const rows = (products || []).filter((product) =>
    productMatchesFilters(product, filters)
  );

  const sorted = [...rows];
  const sortBy = filters.sortBy || "popular";

  if (sortBy === "price-low") {
    sorted.sort((a, b) => a.price - b.price || a.name.localeCompare(b.name));
  } else if (sortBy === "price-high") {
    sorted.sort((a, b) => b.price - a.price || a.name.localeCompare(b.name));
  } else if (sortBy === "newest") {
    sorted.sort((a, b) => String(b.created_at).localeCompare(String(a.created_at)));
  } else if (sortBy === "name") {
    sorted.sort((a, b) => a.name.localeCompare(b.name, "tr"));
  } else {
    sorted.sort(
      (a, b) =>
        Number(b.popularity_score || 0) - Number(a.popularity_score || 0) ||
        Number(a.sort_order || 0) - Number(b.sort_order || 0) ||
        Number(a.id || 0) - Number(b.id || 0)
    );
  }

  return sorted;
}

export function activeProductFilterCount(filters = {}) {
  return [
    normalizedText(filters.search),
    filters.kind,
    filters.rarity,
    filters.availability,
    filters.tag,
    filters.productType,
    filters.onlyAffordable,
    filters.onlyOwned,
  ].filter(Boolean).length;
}
