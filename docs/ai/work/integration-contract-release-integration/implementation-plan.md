# Versioned Integration contract release integration

Goal: carry validated Store PR #32 contract-consumer behavior onto PR #33 release candidate while preserving Admin Audit, Health, Accessibility, Activity, Favorites, Preview, Quick Equip and Loadouts.
Allowed paths: runtime workflow, BaseContract adapter, Preview/Loadouts contract gates, Health diagnostics/UI, focused Ruby/QUnit tests, and this packet.
Relevant context: Store base `a3c35158ab80a04d05dd5b3cb60a6175c0315c28`; source Store PR #32 `8a90a6a9f346e008f8f9594913c76ace888a79bc`; Base PR #46 `8c7f0a0b5ee2c66e5f3f0c6e317f1d69ec3cef33`.
Acceptance: supported v1 manifest is preferred; unsupported or malformed manifests fail closed; legacy Base without a manifest keeps explicit capability fallback; Preview/Loadouts gate through BaseContract; Admin Health reports manifest/legacy/unsupported mode without secrets.
Validation: exact changed-path review, Official Discourse Plugin CI, pinned two-plugin runtime using exact Base PR #46 head.
Risk: T2 cross-plugin public-contract boundary. No Store schema, wallet/ledger, purchase/gift, payment/refund, Orb, ownership or entitlement mutation semantics may change.
Escalation trigger: contract version ambiguity, changed Base method semantics, capability mismatch, authorization regression, or any financial/state mutation outside the existing public APIs.
Merge: prohibited until explicit user authorization.