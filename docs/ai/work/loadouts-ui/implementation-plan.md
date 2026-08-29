# Loadout UI implementation plan

- Goal: expose Base PR #40 saved cosmetic loadouts inside the Store without duplicating authority.
- Base dependency: `discourse-user-cosmetics` exact candidate `7e15ca7176e81194c714f50390152b4892f7669c`.
- Stack base: Store inventory/collections head `d0796c1e21f28c091f898bc73a23a3c511151774`.
- Server: authenticated Store JSON facade calling only `DiscourseUserCosmetics::Integration` loadout methods.
- Security: user scoping stays in Base; foreign IDs remain 404; unavailable apply is rejected atomically.
- Frontend: native `/store/loadouts` route, responsive Glimmer manager, sidebar and inventory entry points.
- Localization: all new client/server copy in EN and TR.
- Scope exclusions: no wallet, payment, refund, purchase, entitlement-schema, or Store database changes.
- Tests: request specs for lifecycle/IDOR/unavailable apply plus QUnit rendering/state coverage.
- Validation: Official Discourse Plugin CI plus pinned two-plugin runtime on the same Store head.
- Merge: never merge without explicit user authorization.
