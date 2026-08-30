# Phase 7 state — availability client i18n

## Base

- Rebuilt on current `main` after storefront i18n PR #66 merged.
- Current main base: `0e916221cd99a1bcd1e4f96053dc786719556e2f`.

## Scope

- localize upcoming, seasonal and limited availability badges
- localize availability detail copy and abbreviated remaining-time units
- preserve availability classification, filter matching and deterministic time calculations
- preserve storefront locale work already present on current main
- keep catalog scheduling, purchase eligibility, pricing, ownership, wallet, payment and server behavior unchanged

## Validation

Require exact-head `Discourse Plugin` and `Cosmetics Integration Runtime Test` to be GREEN before merge.
