# Phase 4 state — Discourse-native client i18n

## Base

- Stacked on `refactor/discourse-native-responsive-phase-3`
- Parent exact head: `95b80ab0907f5d7babf0ae2638a071a317e07519`
- Parent Discourse Plugin CI run #171: GREEN

## Official upstream baseline

Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`:

- `lib/js_locale_helper.rb` loads plugin client translations from `plugins/*/config/locales/client*.LOCALE.yml`, so focused locale files such as `client.storefront.en.yml` and `client.storefront.tr_TR.yml` are supported by core.
- `frontend/discourse/admin/components/dashboard/search.gjs` imports the modern `i18n` API from `discourse-i18n` and resolves user-facing copy through locale keys.

## Scope

- move product-dialog interface copy out of the GJS component
- keep English and Turkish copy in dedicated client locale files
- preserve native `DModal`, `DButton`, and `FormKit` behavior
- add QUnit coverage proving locale-backed copy is actually loaded in the client test environment
- keep purchase, gift validation, ownership, pricing, and server behavior unchanged

## Follow-up

The main storefront component still contains legacy inline UI copy. That migration should be handled in a separate focused phase rather than expanding this dialog-only change set.
