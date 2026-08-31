# Phase 7 state — availability client i18n

## Base

- Refreshed on current `main` after Activity and Favorites native-control phases merged.
- Current main base: `3303bc1a1b015b65fb3251b9b8df847b78900d69`.

## Scope

- localize upcoming, seasonal and limited availability badges
- localize availability detail copy and abbreviated remaining-time units
- preserve availability classification, filter matching and deterministic time calculations
- preserve all newer storefront/admin/native-control work already present on current main
- keep catalog scheduling, purchase eligibility, pricing, ownership, wallet, payment and server behavior unchanged

## Validation

Require exact-head `Discourse Plugin` and `Cosmetics Integration Runtime Test` to be GREEN before merge. Standing user authorization permits merge once both gates are GREEN.
