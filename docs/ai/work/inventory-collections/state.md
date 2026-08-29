# Inventory + Collections state

- Effort: T2 (cross-plugin entitlement read + user-facing route), no schema or financial mutation.
- Base branch: `refactor/use-cosmetics-integration-api-v2` at `4dcf568d3c23d3d00d952384890099f2e053eb15`.
- User Cosmetics dependency: PR #38 exact head `378cdea2a3d9783eeb3cd7f25c86e5b5c17a1001`.
- Authority: direct ownership and entitlement come from the Base Integration contract; Store must not infer either from client state.
- Semantics: `directly_owned` means durable UserItem ownership; `unlocked` means currently entitled, which may also come from groups/defaults/providers.
- No merge until final release authorization.
