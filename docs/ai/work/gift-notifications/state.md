# Gift notification state

- Goal: notify a recipient in Discourse when a Store gift completes successfully.
- Parent checkpoint: `feature/store-purchase-gift-history` at `011a49980627be6c53b6edc16565a86eeb41b8ec`.
- Allowed: notification type registration, post-commit notification delivery, user-menu renderer, EN/TR copy, focused specs, workflow trigger, this packet.
- Authority: GiftService remains the only gift mutation authority; notification data is derived from the committed Gift/Product/User state.
- Acceptance: one native unread notification per successful gift; click opens `/store/history`; sender/product are shown; unrelated notifications are untouched.
- Failure isolation: notification failure must never roll back or falsely report failure for a committed gift.
- No schema, wallet/ledger, price, ownership/grant, payment/refund, or base-plugin contract changes.
- Validation: focused Ruby/QUnit plus latest exact-head official Discourse Plugin CI and two-plugin runtime CI.
- Risk: T2 only around the post-financial side-effect boundary; otherwise T1.
- Keep PR draft; do not merge without explicit user authorization.
