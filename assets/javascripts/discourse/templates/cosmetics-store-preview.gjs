import CosmeticsStorePreview from "../components/cosmetics-store-preview";

<template>
  <CosmeticsStorePreview
    @items={{@model.items}}
    @selections={{@model.selections}}
    @viewer={{@model.viewer}}
  />
</template>
