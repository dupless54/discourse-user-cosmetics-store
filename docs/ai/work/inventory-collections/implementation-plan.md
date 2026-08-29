# Inventory + Collections plan

Goal: add a native Store inventory route and truthful collection progress without new persistence.

Allowed paths:
- `plugin.rb`
- `app/controllers/discourse_cosmetics_store/store_controller.rb`
- `assets/javascripts/discourse/**`
- `assets/stylesheets/**`
- `config/locales/client.*.yml`
- focused request/QUnit specs
- this task packet and the integration runtime workflow trigger

Acceptance:
1. `/store/inventory` is a first-class Store route for logged-in users.
2. Server payload distinguishes direct ownership from current entitlement.
3. Inventory contains deduplicated catalog cosmetics with ownership/unlock state and kind counts.
4. Collection payload exposes unique cosmetic totals, direct-owned/unlocked counts, percentages, and completion.
5. Logged-out payload exposes no personal ownership state.
6. Existing purchase/gift/payment/refund behavior is unchanged.
7. Mobile/light/dark styling uses Discourse variables; new user copy is localized EN/TR.
8. Focused Ruby + QUnit regression coverage and exact-head official/two-plugin CI are green.
