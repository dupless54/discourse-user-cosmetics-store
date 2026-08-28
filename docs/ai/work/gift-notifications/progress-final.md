# Gift notification pre-CI checkpoint

- Parent exact head: `011a49980627be6c53b6edc16565a86eeb41b8ec`.
- Changed paths are limited to notification registration/delivery/rendering, EN/TR copy, focused tests, task docs, and one runtime-workflow branch trigger.
- GiftService financial transaction body is unchanged; only one post-transaction `GiftNotification.deliver` call was added.
- No schema, wallet/ledger, pricing, payment/refund, or base-plugin contract changes.
- Next: draft PR and exact-head CI.
