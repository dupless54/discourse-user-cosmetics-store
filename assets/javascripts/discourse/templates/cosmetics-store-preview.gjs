import CosmeticsStorePreviewStudio from "../components/cosmetics-store-preview-studio";

<template>
  <CosmeticsStorePreviewStudio
    @items={{@model.items}}
    @selections={{@model.selections}}
    @viewer={{@model.viewer}}
  />
</template>
