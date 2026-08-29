# Release Candidate Integration state

- Parent Store checkpoint: PR #22 head `4cc0a255a2e47a4aea99063842e7bb35df359aaf`.
- Integrated sibling feature: PR #20 Inventory Quick Equip behavior, rebased manually onto the current Preview/Rarity chain.
- Preserved: `/store/preview`, preview atomic apply, rarity/limited/seasonal catalog behavior, existing loadouts, and collection progress.
- Added on the integrated chain: server-reported equipped state, authenticated/rate-limited equip and kind-scoped unequip, in-place wardrobe updates, EN/TR copy, and focused request/QUnit coverage.
- Authority: Base `DiscourseUserCosmetics::Integration` remains authoritative for entitlement and selection mutation.
- Safety: no Store schema, wallet, ledger, pricing, purchase, gift, payment, refund, Orb, or ownership semantics changed.
- Validation evidence belongs in PR metadata; do not write final Store head or CI run IDs here.
- Merge status: blocked pending explicit user authorization.
