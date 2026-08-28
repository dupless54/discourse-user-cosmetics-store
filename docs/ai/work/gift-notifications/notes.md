# Upstream API verification

Verified against current Discourse source before implementation:
- `Notification.types` is a mutable `Enum` exposed through Site notification lookup.
- `Notification` publishes unread state after commit.
- `api.registerNotificationTypeRenderer` is the current plugin API used by official bundled plugins.
- Store uses its own `cosmetics_store_gift` notification type and does not override the core `custom` renderer.
