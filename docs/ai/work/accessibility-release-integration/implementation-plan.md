# Store accessibility integration task packet

Goal: carry the already validated keyboard and reduced-motion improvements from PR #26 onto the current PR #27 Favorites + Activity candidate.
Allowed paths: Store preview components, reduced-motion helper, accessibility stylesheet, plugin asset registration, focused QUnit tests, this task packet.
Context: PR #27 exact base `21bed5d4dd0d8c19b5433502853ebe2a6935775e`; PR #26 source base `9d64a76d91a8d1c3685ee4eed5524cb117bd5e23`; source head `22e7200e46ac09961ba3fb5a29c785e1c788e32e`.
Acceptance: respect `prefers-reduced-motion`, suppress motion-heavy preview assets/effect layers while preserving static fallbacks, remove Store transition/hover movement when requested, restore visible `:focus-visible` affordances, and expose hover-preview affordances through keyboard focus.
Authority: presentation-only. No wallet, ledger, payment, purchase, gift, refund, favorite persistence, ownership, entitlement, schema, or Base public API changes.
Validation: focused QUnit as exercised by exact-head Official Discourse Plugin CI; exact-path verification before final checkpoint.
Risk: T1 frontend/presentation integration. Escalate only if source/base preview files diverge, API semantics are touched, or Base contract changes become necessary.
Merge/deploy: forbidden without separate explicit user authorization.
