# Phase 5 state — product-card client i18n

## Base

- Stacked on `refactor/discourse-native-i18n-phase-4`
- Parent exact head: `6abd228dfedfe5678063136bdd9218280a436ec3`
- Parent Discourse Plugin CI run #174: GREEN

## Official upstream baseline

Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`:

- `lib/js_locale_helper.rb` loads plugin `client*.LOCALE.yml` files.
- `frontend/discourse/app/components/post/gap.gjs` imports `i18n` from `discourse-i18n` and passes `{ count: ... }` for locale-aware pluralization.

## Scope

- move product-card labels and accessibility copy out of the GJS component
- keep interpolated product-name labels in client i18n
- use Discourse count/plural handling for item totals
- preserve product open, favorite, gift, availability, ownership and hover-preview behavior
- add a focused QUnit component test for rendered copy and callbacks

## Out of scope

- the internal preview component still has legacy inline copy and can be migrated separately
- the large storefront shell remains untouched in this phase to avoid mixing a broad template rewrite with product-card localization
