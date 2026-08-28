# Wardrobe Quick Equip state

- Branch: `feature/store-wardrobe-quick-equip`, stacked on Store PR #19.
- Base dependency: User Cosmetics PR #40; the integration runtime workflow pins its exact candidate.
- Implemented: server-reported equipped state, Store inventory equip/unequip facade, responsive wardrobe actions, EN/TR copy, and focused Ruby/QUnit coverage.
- Authority: Base `DiscourseUserCosmetics::Integration` remains the only production authority for entitlement and selection mutation.
- Safety: no Store schema, wallet, ledger, purchase, gift, payment, refund, Orb, or catalog ownership semantics changed.
- Validation evidence belongs in PR metadata only; do not write exact Store head or CI run IDs into this tracked state file.
- Merge status: blocked pending explicit user authorization.
