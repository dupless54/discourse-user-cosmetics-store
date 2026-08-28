# Wardrobe Quick Equip plan

Goal: make `/store/inventory` an actionable wardrobe using the Base plugin's public `Integration.equip!` / `unequip!` contract.

Allowed paths: `plugin.rb`, `app/controllers/discourse_cosmetics_store/inventory_controller.rb`, `lib/discourse_cosmetics_store/cosmetics_access.rb`, Inventory frontend/style/locales, focused request/QUnit specs, this task packet, and the integration runtime workflow trigger.
Relevant context: Store PR #19 exact head `3bfb305b5c7edde9e9c98cced377b583ca1177d0`; Base PR #40 exact head `7e15ca7176e81194c714f50390152b4892f7669c`.
Acceptance: server reports equipped state; entitled items can be equipped; a kind can be unequipped; unauthorized/unavailable items are rejected by Base authority; client never supplies authoritative entitlement; UI updates without reload; EN/TR + mobile/light/dark remain native.
Validation: focused request/QUnit coverage, exact diff review, Official Discourse Plugin CI, pinned two-plugin runtime.
Risk: cross-plugin public contract + authorization; no wallet/payment/refund/schema changes.
Effort tier: T2 for endpoint/contract boundary, T1 for UI/locales/tests.
Escalation trigger: Base contract mismatch, authorization ambiguity, or selection consistency failure.
