# Store purchase + gift history plan

Goal: add a private `/store/history` surface for the signed-in member's Store-owned purchase and gift records.

Allowed paths:
- `plugin.rb`
- `app/controllers/discourse_cosmetics_store/history_controller.rb`
- `assets/javascripts/discourse/**history**`
- existing inventory/sidebar navigation touchpoints
- `config/locales/client.*.yml`
- focused request/QUnit specs
- this task packet

Acceptance:
1. Anonymous API responses expose no personal history.
2. Signed-in users see only their own purchases, outgoing gifts, and incoming gifts.
3. Historical `price_paid`, status, product presentation, date, and gift counterpart are rendered from server state.
4. Response is private/no-store and omits idempotency/payment capability/internal audit data.
5. UI is first-class `/store/history`, localized EN/TR, mobile/light/dark compatible, and reachable from Store account navigation.
6. Existing purchase/gift/payment/refund/wallet behavior and schema are unchanged.
7. Focused Ruby + QUnit coverage and exact-head official Discourse CI are GREEN; integration runtime remains GREEN when triggered.
