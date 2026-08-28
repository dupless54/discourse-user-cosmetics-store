# Gift notification implementation plan

Goal: add a native Discourse notification for completed Store gifts without changing gift financial semantics.

Allowed paths:
- `plugin.rb`
- `lib/discourse_cosmetics_store/gift_service.rb`
- Store notification initializer under `assets/javascripts/discourse/initializers/`
- EN/TR client locale files
- focused Ruby/QUnit specs
- integration workflow branch trigger
- this task packet

Acceptance:
1. Store registers a dedicated notification type without replacing core/custom notification rendering.
2. A successful gift creates one unread recipient notification containing only safe sender/product presentation data.
3. Notification click routes to `/store/history` and renders with a gift icon plus localized EN/TR text.
4. Failed/rejected gifts create no notification.
5. Notification persistence/rendering failures cannot undo or misreport an already committed gift.
6. Existing wallet debit, idempotency, grant, purchase-count, payment/refund, schema, and base-plugin behavior stay unchanged.
7. Exact-head official Discourse CI and two-plugin runtime CI must be GREEN before checkpoint completion.
