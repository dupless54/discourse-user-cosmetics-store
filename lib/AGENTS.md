# Cosmetics Store service layer

High-risk financial boundary.

- Wallet and ledger writes are atomic and auditable; never mutate balance without corresponding durable ledger semantics.
- Purchase/fulfillment/refund/event services must be idempotent under retries and race-safe.
- Provider adapters validate signatures/tokens and normalize external state; provider responses are untrusted input.
- HTTP calls use bounded timeouts, safe redirects/URLs, and sanitized logging.
- Secret keys/webhook secrets/provider credentials never enter client payloads or logs.
- Base-cosmetics integration loads only the intentional public model/presenter surface and remains Store -> base.
