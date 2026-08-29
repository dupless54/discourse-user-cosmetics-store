# Admin Health release integration task packet

Goal: carry the already validated read-only Cosmetics Store Admin System Health diagnostics from PR #28 onto the current PR #29 accessibility release candidate.
Allowed paths: runtime workflow branch trigger, Store admin health component/template, admin controller read projection, accessibility/admin panel stylesheet extension, read-only HealthCheck service, focused RSpec/request/QUnit coverage, this task packet.
Context: PR #29 exact base `d529da391ef5f2fcdd504917cbd18e1b2bfcee45`; PR #28 source base `22e7200e46ac09961ba3fb5a29c785e1c788e32e`; source head `93b1c4d5efcdf57042faaaa60595f8ed180642ee`.
Acceptance: existing admin-only catalog response includes observational `health`; report Store/Base/public Integration/Preview/Loadout readiness, catalog integrity warnings, and configured provider counts only; never expose provider credentials/secrets; no repair or mutation action.
Authority/security: preserve existing AdminConstraint/AdminController authorization. Health diagnostics are read-only and must not alter wallet, ledger, pricing, purchase/gift fulfillment, payment/refund state, favorites, ownership, entitlement, schema, or Base public API.
Validation: exact-head Official Discourse Plugin CI AND pinned Cosmetics Integration Runtime Test must both complete GREEN; verify exact changed paths and unchanged parent head before final checkpoint.
Risk: T2 because this touches an admin controller, a cross-plugin public-contract diagnostic, and provider configuration visibility. Escalate on any secret-field exposure, mutation, authorization drift, Base contract ambiguity, or runtime failure.
Merge/deploy: forbidden without separate explicit user authorization.
