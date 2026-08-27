# Cosmetics Store frontend

- Client consumes server catalog/wallet/payment APIs; it never calculates authoritative balances, ownership, fulfillment, or refund state.
- Treat payment tokens as sensitive capabilities; do not persist/log them unnecessarily.
- Handle pending/success/failure/refund states explicitly and tolerate retries/reloads.
- Use current Discourse/Glimmer conventions, locale-backed copy, safe escaping, and mobile/light/dark compatibility.
- Do not couple directly to base plugin internals when existing Store APIs provide the needed surface.
