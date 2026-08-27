# Durable decisions

Load only when architecture, payment, refund, or dependency behavior is relevant.

- Dependency direction is Store -> User Cosmetics; the base cosmetic plugin does not depend on Store without explicit redesign.
- Wallet/ledger mutations are atomic, replay-safe, and auditable; balance is never derived from client state.
- Provider callbacks/webhooks are authenticated and idempotent before credit or fulfillment.
- Refunds must reverse economic value safely: no retained spendable credit, duplicate reversal, or unaudited state transition.
- External provider calls use bounded timeouts/errors and secrets/PII are never exposed through logs or serializers.
- Admin wallet/catalog/package/refund mutations remain server-authorized.

Do not record temporary PR/CI/payment incident status here; use `CURRENT_STATE.md` for volatile facts.
