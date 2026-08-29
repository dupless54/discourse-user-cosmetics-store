# State

- Parent Store PR: #21 (`feature/cosmetics-live-preview-studio`), exact branch point `9da2145ef83f62e23cc7f2dddbac0c50037e61aa`.
- Working branch: `feature/cosmetics-rarity-limited-seasonal`.
- No Base plugin change is planned for this phase.
- `Product.available_now?` remains the authoritative purchase/gift gate.
- Limited/seasonal scheduling affects acquisition only; existing cosmetic ownership/equip entitlement is not revoked when a window ends.
- No schema/migration, wallet, payment, refund, grant, or Orb behavior changes.