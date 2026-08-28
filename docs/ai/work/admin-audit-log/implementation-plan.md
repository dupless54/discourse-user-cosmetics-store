# Admin Audit Log — implementation plan

Goal: make successful Store admin mutations visible in a durable, admin-only audit trail without adding a plugin-specific audit table.

Architecture:
- use Discourse core `StaffActionLogger#log_custom`, which writes admin-only `UserHistory` staff actions;
- use Store-owned custom types prefixed with `cosmetics_store_`;
- serialize only recent Store-owned custom staff actions into the existing admin catalog payload;
- do not duplicate provider callback payloads or wallet/payment secrets.

Actions covered:
- product create/update/delete;
- mission create/update/delete/disable;
- manual wallet adjustment (amount/target/result only; never free-form reason);
- Orb package create/update/delete/disable (never provider credentials/config values);
- manual refund record (internal payment/refund IDs and amounts only; never provider refund token/callback payload).

Financial boundaries:
- ledger remains authoritative for wallet balances;
- PaymentEvent/PaymentRefund remain authoritative for payment/refund lifecycle;
- StaffActionLogger is the human admin-action trail, not a replacement for financial ledgers;
- where practical, mutation + staff log share an outer DB transaction so a successful admin mutation is not silently unaudited.

UI: read-only recent audit panel under the existing admin management surface with client-side action/actor search.

No schema/migration, no new public endpoint, no secret/PII payloads, no repair actions.
Validation: Store RSpec + admin QUnit + Official Discourse Plugin CI + pinned two-plugin runtime.
