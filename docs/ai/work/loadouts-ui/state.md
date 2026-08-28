# Loadout UI state

- Draft PR: #19, stacked on Store PR #16.
- Base dependency: User Cosmetics PR #40 exact head `7e15ca7176e81194c714f50390152b4892f7669c`.
- Implemented: Store JSON facade, route, responsive UI, sidebar/inventory discovery, EN/TR copy.
- Security: authenticated endpoints, Base-owned user scoping, foreign IDs preserve 404, atomic apply remains Base-owned.
- Tests added: request lifecycle/IDOR/unavailable apply and QUnit render/state coverage.
- Runtime workflow pins the exact Base PR #40 head.
- Validation status: pending exact-head Official Discourse CI and pinned two-plugin runtime.
- Merge status: blocked; explicit user authorization required after final GREEN checkpoint.
