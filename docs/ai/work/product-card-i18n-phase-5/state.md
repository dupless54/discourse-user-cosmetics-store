# Phase 5 state — product-card client i18n

## Base

- Rebuilt on current `main` after the clean Phase 4 merge.
- Phase 4 merge commit: `f1f017875905fc32f07421b24bf8f96372dfd86a`.

## Official upstream baseline

Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`:

- `lib/js_locale_helper.rb` loads plugin `client*.LOCALE.yml` files.
- `frontend/discourse/app/components/post/gap.gjs` imports `i18n` from `discourse-i18n` and passes `{ count: ... }` for locale-aware pluralization.

## Scope

- move product-card labels and accessibility copy out of the GJS component;
- keep interpolated product-name labels in client i18n;
- use Discourse count/plural handling for item totals;
- preserve product open, favorite, gift, availability, ownership and hover-preview behavior;
- add a focused QUnit component test for rendered copy and callbacks.

## Out of scope

- the internal preview component still has legacy inline copy and will be migrated separately;
- the large storefront shell remains untouched in this phase to avoid mixing a broad template rewrite with product-card localization.
