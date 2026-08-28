import CosmeticsStoreInventory from "../components/cosmetics-store-inventory";

<template>
  <CosmeticsStoreInventory
    @inventory={{@model.inventory}}
    @viewer={{@model.viewer}}
  />
</template>
