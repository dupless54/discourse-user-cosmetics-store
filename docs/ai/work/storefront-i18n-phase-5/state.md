# Phase 5 state — Discourse-native storefront i18n

## Base

- Current `main` after Phase 4 merge: `f1f017875905fc32f07421b24bf8f96372dfd86a`

## Official upstream baseline

Validated against the current Discourse core revision already pinned by the repository modernization work:

- `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`
- `frontend/discourse-i18n/src/index.js`
- `frontend/discourse/app/components/language-switcher.gjs`
- modern GJS templates importing `i18n` from `discourse-i18n`

Current core exposes the active locale through the default `I18n` instance and exposes the BCP-47 form through `I18n.currentBcp47Locale`. Storefront search case-folding and name collation therefore follow the active Discourse locale instead of forcing Turkish rules.

## Scope

- move the remaining main storefront shell/navigation/featured/browse/Orbs/collections/favorites interface copy into plugin client locale files
- use `i18n` directly from `discourse-i18n` in the GJS template
- use `I18n.currentBcp47Locale` for locale-sensitive search and name sorting
- extend navigation QUnit coverage to prove locale-backed copy is loaded
- preserve route names, product data, purchase/gift/favorite calls, wallet state, mission claims, payment behavior, entitlement checks, schema, and server responses

## Gate

Merge only after Official Discourse Plugin CI and the cross-plugin Cosmetics Integration Runtime Test are GREEN for the latest exact PR head SHA.
