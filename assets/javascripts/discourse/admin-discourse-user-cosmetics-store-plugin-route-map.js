export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("cosmetics-store-catalog", { path: "catalog" });
  },
};
