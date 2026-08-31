# Phase 11B — Payment admin task packet

Goal: Move Orb package and manual Shopier refund administration to current Discourse-native admin UI without changing financial semantics.
Allowed paths: admin payment/package components and routes/templates, admin route map, EN/TR admin locales, focused JS tests, this task packet.
Relevant context: existing `/admin/plugins/user-cosmetics-store` package/refund endpoints; `OrbPackage` validation; `PaymentRefundService`; current DModal/FormKit APIs.
Acceptance: package list/new/edit use native routes/FormKit; provider/payment lists are responsive `d-table`; manual refund uses DModal + FormKit with explicit confirmation; all copy locale-backed.
Validation: exact changed paths; Official `Discourse Plugin` CI; `Cosmetics Integration Runtime Test`; focused QUnit via CI.
Risk: T2 financial UI boundary. Server-returned payment/refund state remains authoritative; no wallet/refund/package backend arithmetic or authorization changes.
Escalation trigger: any need to alter refund math/idempotency, package persistence rules, provider callbacks, schema, or payment service behavior.
