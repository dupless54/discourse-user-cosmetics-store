# Phase 12 — Native admin overview task packet

Goal: Finish the Store admin migration by modernizing the read-only Overview health and audit surfaces.
Allowed paths: health/audit admin components, overview template, EN/TR admin locales, focused QUnit, this task packet.
Relevant context: Overview model is read-only health + StaffActionLogger audit data; current Discourse UI-kit/d-table patterns already used by Products/Missions/Payments/Wallets.
Acceptance: no hard-coded UI copy; health diagnostics and audit entries are responsive/native; audit filters use supported Discourse controls; Open Store/reset actions use UI-kit; existing filtering/value semantics preserved.
Validation: exact changed paths; Official `Discourse Plugin` CI; `Cosmetics Integration Runtime Test`; focused QUnit via CI.
Risk: T1 read-only admin UI. No backend health checks, audit serialization/logging, authorization, schema, payment, wallet, or Store behavior changes.
Effort tier: T1.
Escalation trigger: any need to change audit payloads, server health semantics, authorization, or persistence.
