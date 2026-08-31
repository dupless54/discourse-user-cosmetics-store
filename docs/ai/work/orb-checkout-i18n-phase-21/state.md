# Phase 21 — Orb checkout client i18n

Goal: remove hard-coded Orb checkout UI copy and provide English/Turkish client locale keys without changing payment behavior.
Allowed paths: Orb purchases component, focused QUnit test, dedicated EN/TR client locale files, and this task packet.
Relevant context: storefront components use `discourse-i18n`; locale-backed UI copy is required by the frontend rules.
Acceptance: package/provider/billing/checkout UI renders from locale keys; dynamic amount/currency/provider data is preserved; `Türkiye` remains the existing billing default value; payment status/provider labels remain server data.
Validation: focused QUnit assertions for English copy plus exact changed-path validation; latest exact PR head must pass `Discourse Plugin` and `Cosmetics Integration Runtime Test` before merge.
Risk: T1 copy refactor with T2 validation because the component sits on the payment UI boundary; request/redirect/provider logic remains unchanged.
Effort tier: T1 implementation, T2 validation boundary.
Escalation trigger: any change to billing defaults/requiredness, endpoint payload, provider selection semantics, payment state, wallet, or refunds.
