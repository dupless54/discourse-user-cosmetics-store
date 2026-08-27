# Cosmetics Store app layer

- Controllers never accept client payment/ownership/balance state as authority.
- Models preserve purchase/gift/mission/payment/refund/event relationships and uniqueness.
- Public payment status/return endpoints expose minimum safe state; tokens are capabilities and must remain unguessable/non-leaking.
- Admin controllers remain `AdminConstraint`/server-authorized for catalog, wallet, packages, and refunds.
- Callback/webhook controllers validate provider authenticity before invoking fulfillment/event services.
