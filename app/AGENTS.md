# Cosmetics Store app layer

Apply the backend sections of `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md` for controllers, models, serializers/presenters, routes, and Rails loading conventions.

- Controllers never accept client payment/ownership/balance state as authority.
- Keep controllers thin; coordinate non-trivial purchase/gift/payment/refund/fulfillment flows through service objects instead of controller orchestration or callback-heavy models.
- Models preserve purchase/gift/mission/payment/refund/event relationships and uniqueness.
- Never serialize an ActiveRecord model wholesale. Public/admin JSON must use an intentional serializer/presenter or explicit safe field hash so newly added model attributes cannot leak by accident.
- Public payment status/return endpoints expose minimum safe state; tokens are capabilities and must remain unguessable/non-leaking.
- Admin controllers remain `AdminConstraint`/server-authorized for catalog, wallet, packages, and refunds.
- Callback/webhook controllers validate provider authenticity before invoking fulfillment/event services.
- Follow current Discourse route/controller conventions and keep authorization server-side.
- Prefer conventional Rails engine/app paths and Zeitwerk autoloading for application classes; do not grow `plugin.rb` into a manual `require_relative` registry for code Rails can autoload.
