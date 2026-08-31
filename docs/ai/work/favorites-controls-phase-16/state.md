# Phase 16 — Discourse-native Favorites controls

## Goal
Modernize the public Favorites page interaction primitives so they follow current Discourse UI-kit conventions without changing favorite, purchase, gift, wallet, filtering, or product-dialog business logic.

## Allowed paths
- `assets/javascripts/discourse/components/cosmetics-store-favorites-page.gjs`
- `test/javascripts/components/cosmetics-store-favorites-page-test.gjs`
- `test/javascripts/components/cosmetics-store-responsive-filters-test.gjs` only if the native disclosure regression requires it
- this task packet

## Required changes
- replace raw Favorites navigation, balance, login, empty-state, filter disclosure/reset controls with `DButton` where compatible
- preserve the existing router transitions and active Favorites state
- preserve search/select/checkbox DOM contracts and responsive filter behavior
- preserve favorite toggle, purchase, gift, wallet updates, and product dialog behavior unchanged
- add focused QUnit coverage for native Favorites navigation/reset/disclosure semantics

## Out of scope
No backend/controller/service/model/schema changes. No purchase/gift/favorite endpoint changes. No wallet math. No product filtering algorithm changes. No stylesheet or locale changes unless a concrete CI/runtime failure requires a narrowly justified fix.

## Merge gate
Exact changed-path validation plus Official `Discourse Plugin` CI and `Cosmetics Integration Runtime Test` GREEN on the latest exact PR head SHA. Standing user authorization permits merge once these gates are satisfied.
