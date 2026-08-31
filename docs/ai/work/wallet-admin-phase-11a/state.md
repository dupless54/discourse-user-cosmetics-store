# Wallet admin phase 11A

Goal: modernize the admin wallet lookup/adjustment UX with native Discourse FormKit, dialog confirmation, and d-table ledger presentation.
Allowed paths: wallet admin component/template if needed, admin locales, focused admin QUnit, this state file.
Relevant context: admin/AGENTS.md, lib/AGENTS.md, DECISIONS.md, current wallet controller/service contract, current Discourse FormKit/dialog/d-table patterns.
Acceptance: server remains source of truth; lookup is FormKit-backed; adjustment requires explicit confirmation and posts only server-authorized username/amount/reason; ledger renders responsively; copy is locale-backed.
Validation: exact changed-path review, Official Discourse Plugin CI, Cosmetics Integration Runtime Test.
Risk: T2 financial UI boundary; no balance calculation, ledger semantics, authorization, endpoint, schema, payment/refund, or public Store behavior changes.
Escalation trigger: any need to change wallet service/controller semantics, server validation, ledger records, or authorization.
