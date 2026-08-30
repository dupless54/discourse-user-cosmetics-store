# Phase 3 state — Discourse-native responsive storefront

## Base

- Rebuilt on current `main` after Phase 2 merge.
- Current Phase 2 merge: `a6c3d982fd65eba1a0a3ee6b743c3cdbd5a81809`.

## Official upstream baseline

Validated against the Discourse core revision used by current plugin CI:

- `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`
- `app/assets/stylesheets/lib/breakpoints.scss`
- `app/assets/stylesheets/lib/container.scss`
- `app/assets/stylesheets/lib/viewport.scss`

Use the shared `xs`, `sm`, `md`, `lg`, `xl`, and `2xl` breakpoint vocabulary. Storefront components respond to their own inline size through `lib/container`; viewport helpers are reserved for route-shell concerns such as safe-area padding.

## Scope

- named storefront container-query authority for page content;
- shared-breakpoint responsive rules for Preview Studio, browse/filter layout, headings, loadouts, activity, product grids and hero content;
- dedicated Phase 2 navigation responsive ownership remains separate;
- native Phase 1 `DModal` responsive ownership remains separate;
- no routing, purchase, gift, wallet, payment, entitlement or serializer behavior changes.

The legacy mobile stylesheet remains a compatibility layer for now. Removal of superseded rules requires its own visual/regression cleanup rather than a destructive mixed refactor.
