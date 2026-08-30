# Phase 7 state — Discourse-native server i18n

## Base

- Branch started from `e23ee5e9d421f35b09260b972567a316fe81f1b9`.
- The phase only touches server/controller locale generation, so it remains independent from the concurrently completed client storefront-i18n phase.

## Scope

- replace hard-coded Turkish StoreController response labels with server I18n keys
- replace hard-coded Turkish AdminController validation, mission metric, and refund validation copy with server I18n keys
- localize cosmetic-kind, availability-filter, and anonymous preview-user labels
- add English and Turkish server locale entries
- add request coverage proving default-English responses come from the locale layer

## Invariants

No purchase/gift/favorite state transition, wallet arithmetic, payment/refund accounting, entitlement, database schema, route, authorization, or serialization shape is changed.

## Gate

Merge only after Official Discourse Plugin CI and the cross-plugin Cosmetics Integration Runtime Test are GREEN on the latest exact PR head SHA.
