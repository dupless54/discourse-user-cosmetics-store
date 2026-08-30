export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("cosmetics-store-catalog", { path: "catalog" });
    this.route("cosmetics-store-products", { path: "products" });
    this.route("cosmetics-store-missions", { path: "missions" });
    this.route("cosmetics-store-payments", { path: "payments" });
    this.route("cosmetics-store-wallets", { path: "wallets" });
  },
};
