# Phase 4 state — Discourse-native product-dialog i18n

## Base

- Rebuilt on current `main` after Phase 3 merge.
- Current Phase 3 merge: `b348d62c2566d601d72b0297834a774c217e91a0`.

## Official upstream baseline

Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`:

- plugin client translations are loaded from `config/locales/client*.LOCALE.yml`;
- modern GJS components use `i18n` from `discourse-i18n`;
- native `DModal`, `DButton`, and FormKit remain authoritative for the dialog interaction.

## Scope

- product-dialog interface copy is locale-backed in English and Turkish;
- purchase/gift labels and FormKit copy use Discourse i18n;
- existing purchase, gift, pricing, ownership and validation behavior is unchanged;
- focused QUnit continues to cover native modal rendering, localized copy, purchase callback and normalized gift recipient.

Broader storefront and admin copy are handled in later focused phases so each exact-head CI result remains attributable to a small change set.
