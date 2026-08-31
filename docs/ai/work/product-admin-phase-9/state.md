# Product admin phase 9

Goal: move Store product management to native Discourse list/new/edit admin flow.
Allowed paths: product admin routes/templates/components, client admin locales, focused admin QUnit, this state file.
Relevant context: current source/tests, admin/AGENTS.md, current Discourse nested plugin-admin routes, FormKit, DButton/dialog, d-table, AdminConfigAreaEmptyList.
Acceptance: products index has native list/empty state; new/edit are URL-addressable; FormKit persists through existing endpoints; delete uses dialog service; no legacy inline editor.
Validation: exact changed-path review, Official Discourse Plugin CI, Cosmetics Integration Runtime Test.
Risk: T1 UI refactor; no wallet/payment/refund/schema/public Store semantics may change.
Escalation trigger: any server contract, authorization, persistence rule, financial behavior, or schema change.
