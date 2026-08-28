# Store purchase + gift history state

- Effort: T2 for privacy/authorization boundary; no financial mutation.
- Stacked base: `feature/cosmetics-inventory-collections` at `d0796c1e21f28c091f898bc73a23a3c511151774`.
- Authority: Purchase/Gift rows are server-owned Store history; client never supplies history ownership, price, status, or counterpart identity.
- Privacy: `/cosmetics-store/history.json` is `private, no-store`; anonymous visitors receive no personal rows.
- Scope: current user's purchases, gifts sent, gifts received, EN/TR UI, Store sidebar/cross-links, request + QUnit coverage.
- No schema, wallet/ledger, purchase/gift mutation, payment/provider, refund, or base-plugin behavior changes.
- Keep the checkpoint PR draft; no merge until explicit final release authorization.
