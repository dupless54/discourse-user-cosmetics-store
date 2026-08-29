import CosmeticsStoreLoadouts from "../components/cosmetics-store-loadouts";

<template>
  <CosmeticsStoreLoadouts
    @loadouts={{@model.loadouts}}
    @viewer={{@model.viewer}}
  />
</template>
