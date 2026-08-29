# Gift notification release integration

Goal: restore the already validated native Store gift notification behavior on top of the current PR #34 release candidate, without restoring the superseded `/store/history` UI.
Allowed paths: notification type/plugin wiring, GiftNotification service, one post-commit GiftService delivery call, notification initializer, EN/TR notification copy, focused Ruby/QUnit/integration tests, runtime branch trigger, and this packet.
Relevant context: Store base `bf5ba163ce7b5a23d9df19171502e2cde1786b28`; source Store PR #18 `2ed052917e2e750cf9d3d2799f2ed89c8200a5ed`; Base PR #46 `8c7f0a0b5ee2c66e5f3f0c6e317f1d69ec3cef33`.
Acceptance: a successfully committed gift creates one native unread in-app notification; retry is idempotent; notification failure cannot roll back or falsely fail a committed gift; rejected gifts create no notification; click target is `/store/activity`; no new email channel.
Validation: exact changed-path review, Official Discourse Plugin CI, pinned two-plugin runtime using exact Base PR #46 head.
Risk: T2 because gift delivery follows a financial transaction. The existing transaction body, wallet debit, ledger, grant, idempotency, pricing, payment/refund, and Base contract semantics must remain unchanged.
Escalation trigger: any notification work enters the gift transaction, changes financial truth, exposes sensitive data, adds email delivery, or requires restoring the old History route.
Merge: prohibited until explicit user authorization.