# Phase 20 — native Orb checkout actions

Goal: move standard provider selection and checkout-submit controls to current Discourse `DButton` without changing payment behavior.
Allowed paths: Orb purchases component, its focused QUnit test, and this task packet.
Relevant context: current Discourse `DButton` supports action/actionParam, translatedLabel, ariaPressed, disabled state, and submit type.
Acceptance: package selection, provider state, native form submit, billing fields, DModal, `/cosmetics-store/payments.json` payload, redirect, and busy handling remain unchanged.
Validation: focused QUnit plus exact changed-path validation; latest exact PR head must pass `Discourse Plugin` and `Cosmetics Integration Runtime Test` before merge.
Risk: T2 because this touches the payment UI boundary; no financial semantics, server, callback, provider-validation, wallet, or refund changes.
Effort tier: T2 for validation, bounded frontend implementation.
Escalation trigger: any need to alter endpoint payload, provider validation, billing requiredness, server state, wallet, fulfillment, or refund behavior.
