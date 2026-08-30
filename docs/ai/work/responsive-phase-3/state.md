# Phase 3 state — Discourse-native responsive storefront

## Base

- Stacked on `refactor/discourse-native-navigation-phase-2`
- Parent exact head: `873f7c3c2f688115995d42be1fe404582bdfa8d6`
- Parent Discourse Plugin CI run #168: GREEN

## Official upstream baseline

Validated against the exact Discourse core revision used by the latest plugin CI at the start of this phase:

- `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`
- `app/assets/stylesheets/lib/breakpoints.scss`
- `app/assets/stylesheets/lib/container.scss`
- `app/assets/stylesheets/lib/viewport.scss`

The upstream breakpoint scale is `xs: 20rem`, `sm: 40rem`, `md: 48rem`, `lg: 64rem`, `xl: 80rem`, `2xl: 96rem`. New storefront layout decisions must use these shared helpers where width is the deciding factor instead of adding new arbitrary pixel breakpoints.

## Scope

- introduce one storefront container-query authority for page content
- use `lib/container` for component/layout width changes
- use `lib/viewport` only for viewport-owned page-shell concerns such as safe-area padding
- preserve the dedicated Phase 2 navigation responsive layer
- preserve the dedicated Phase 1 `DModal` responsive layer
- keep store routing, purchasing, gifting, ownership and payment behavior unchanged

## Follow-up

The legacy `discourse-cosmetics-store-mobile.scss` remains registered as a compatibility layer in this phase. The new native layer loads after it and becomes authoritative for the broad storefront layout. A later cleanup may delete superseded legacy width rules after visual/runtime validation, rather than mixing a large destructive stylesheet rewrite into this phase.
