# Loadout UI state

- Draft PR: #19, stacked on Store PR #16.
- Base dependency: User Cosmetics PR #40 exact candidate `7e15ca7176e81194c714f50390152b4892f7669c`.
- Implemented: Store JSON facade, route, responsive UI, sidebar/inventory discovery, EN/TR copy.
- Security: authenticated endpoints, Base-owned user scoping, foreign IDs preserve 404, atomic apply remains Base-owned.
- Tests: request lifecycle/IDOR/unavailable atomic apply and QUnit render/state coverage.
- The first runtime candidate exposed an invalid test fixture: an ungrouped Base cosmetic is public by design, so revoking direct ownership did not remove entitlement. The fixture now uses a group-restricted saved cosmetic and verifies a real entitlement loss without changing production behavior.
- Exact-head CI evidence is recorded in PR #19 so updating this tracked state file never makes its own validation references stale.
- Merge status: blocked; explicit user authorization required.
