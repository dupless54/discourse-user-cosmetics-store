import CosmeticsStoreHistory from "../components/cosmetics-store-history";

<template>
  <CosmeticsStoreHistory
    @history={{@model.history}}
    @viewer={{@model.viewer}}
  />
</template>
