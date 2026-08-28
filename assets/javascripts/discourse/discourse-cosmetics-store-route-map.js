export default function cosmeticsStoreRoutes() {
  this.route("cosmetics-store", { path: "/store" });
  this.route("cosmetics-store-browse", { path: "/store/browse" });
  this.route("cosmetics-store-browse-category", {
    path: "/store/browse/:category",
  });
  this.route("cosmetics-store-orbs", { path: "/store/orbs" });
  this.route("cosmetics-store-favorites", { path: "/store/favorites" });
  this.route("cosmetics-store-inventory", { path: "/store/inventory" });
  this.route("cosmetics-store-loadouts", { path: "/store/loadouts" });
  this.route("cosmetics-store-preview", { path: "/store/preview" });
  this.route("cosmetics-store-collections", { path: "/store/collections" });
  this.route("cosmetics-store-collection", {
    path: "/store/collections/:collection_slug",
  });
}
