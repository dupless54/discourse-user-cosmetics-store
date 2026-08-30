# Cosmetics Store service layer

High-risk financial boundary. Apply the backend/service guidance in `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md`.

- Wallet and ledger writes are atomic and auditable; never mutate balance without corresponding durable ledger semantics.
- Purchase/fulfillment/refund/event services must be idempotent under retries and race-safe.
- Use explicit service objects to coordinate multi-step business actions; keep controllers thin and avoid hiding critical workflow in model callbacks.
- Provider adapters validate signatures/tokens and normalize external state; provider responses are untrusted input.
- HTTP calls use bounded timeouts, safe redirects/URLs, and sanitized logging.
- Secret keys/webhook secrets/provider credentials never enter client payloads or logs.
- Base-cosmetics integration loads only the intentional public model/presenter surface and remains Store -> base.
- Prefer Rails/Zeitwerk autoloading and conventional engine paths for service/application code; add manual `require_relative` loading only when current Discourse/Rails loading rules actually require it.
- Service return values/errors should expose only the data the caller needs; do not pass raw ActiveRecord objects into JSON rendering as a shortcut.
