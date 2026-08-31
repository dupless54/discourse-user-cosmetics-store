# Mission admin phase 10

Goal: move Orb mission management to native Discourse list/new/edit admin flow.
Allowed paths: mission admin routes/templates/components, admin locales, focused admin QUnit, this state file.
Relevant context: admin/AGENTS.md, current products phase pattern, current Discourse FormKit/DButton/dialog/d-table conventions.
Acceptance: missions index has native list/empty state; new/edit are URL-addressable; FormKit persists through existing mission endpoints; delete uses dialog service; no legacy inline editor.
Validation: exact changed-path review, Official Discourse Plugin CI, Cosmetics Integration Runtime Test.
Risk: T1 UI refactor; mission eligibility/claim calculation, wallet arithmetic, payment/refund/schema/public Store behavior remain unchanged.
Escalation trigger: server mission semantics, authorization, persistence contract, wallet behavior, or schema change.
