# Current state
Main baseline at context setup: `4c60f79960c9fac864b4c8e8a02930df1790834f`.

No active multi-session packet was recorded at setup. Before work, inspect current branch/PR/source/tests. Key durable boundary: this Store depends on `discourse-user-cosmetics`; wallet/ledger/payment/refund state is server-authoritative and provider callbacks are untrusted until authenticated.
