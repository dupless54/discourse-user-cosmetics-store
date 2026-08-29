# Store Activity Center task packet

Goal: add a private `/store/activity` page for the signed-in member's cosmetic purchases, sent/received gifts, and non-duplicate Orb activity.
Allowed paths: activity controller/spec; Store route wiring; activity route/template/component/style/tests; sidebar/nav; EN/TR locales; runtime workflow if needed; this task packet.
Relevant context: PR #23 exact head `78b3420d60106a5489034c5a9580069488897d9e`; Store owns purchase/gift/wallet/ledger records.
Acceptance: only current-user records; no payment tokens/idempotency keys/provider payloads/admin notes; private/no-store response; useful empty/login states; mobile/theme compatible.
Projection rule: purchases and gifts are first-class events; ledger `purchase`/`gift` rows are excluded from Orb events to avoid duplicate timeline entries.
Validation: request specs for auth/isolation/projection + component QUnit + exact diff + Official Discourse Plugin CI; pinned two-plugin runtime when workflow runs on branch.
Risk: privacy/financial projection only; no mutations, schema, wallet math, payment/refund, ownership, entitlement, or Base contract changes.
Effort tier: T2 for server projection/privacy review, then T1 for UI/tests.
Escalation: stop if safe event attribution requires exposing provider/payment capabilities or changing ledger semantics.