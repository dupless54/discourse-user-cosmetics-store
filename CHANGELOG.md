# Changelog

All notable changes to `discourse-user-cosmetics-store` are documented here.

The completed roadmap is merged to `main`, but its release version/tag has not been assigned yet. Until that release decision is made, the merged work remains under **Unreleased**.

## Unreleased

### Added

- Inventory and Collections surfaces backed by the existing Store/Base ownership model.
- Saved cosmetic Loadout Manager using the Base public loadout contract.
- Live Preview Studio for composing all four cosmetic slots locally and applying the complete selection atomically.
- Limited and seasonal storefront presentation with rarity, upcoming/active/ended availability states, badges, countdown copy, and acquisition-safe filtering.
- Filterable Favorites Center with search, cosmetic/product type, rarity, availability, tags, affordability, ownership, and sorting controls.
- Inventory Quick Equip actions backed by the Base public selection contract.
- Private Store Activity Center covering purchases, sent/received gifts, Orb activity, and wallet summary without exposing other users' financial state.
- Private purchase/gift history surface.
- Native in-app gift notifications with best-effort post-commit delivery.
- Read-only Admin System Health diagnostics for Store/Base readiness, public capabilities, catalog consistency, availability windows, and configured payment-provider counts.
- Native Store admin audit log using Discourse staff history with whitelist-only metadata.
- Version-aware `BaseContract` adapter that consumes Base Integration Contract v1 and preserves legacy fallback only when no manifest exists.

### Changed

- Gift notification clicks now open the unified `/store/activity` center.
- Store previews and interactive controls respect reduced-motion preferences and expose visible keyboard focus states.
- Mobile Store layouts, dialogs, previews, navigation, and narrow-screen overflow handling were hardened while preserving desktop behavior.
- Browse dropdown layering and hover behavior were corrected and retained through the final release merge.
- Cross-plugin Integration Runtime CI now runs for every pull request targeting `main` and again on `main` pushes, checking out the exact Store revision being validated.

### Safety and compatibility

- Store remains dependent on `discourse-user-cosmetics`; the Base plugin does not depend on Store.
- Wallet, ledger, purchase, gift, payment, fulfillment, and refund authority remain server-side.
- Gift notifications run only after the gift transaction commits and cannot roll back a completed financial action if notification persistence fails.
- Unsupported or malformed Base contract manifests fail closed; older Base installations without a manifest retain explicit legacy public-method probing.
- No release tag or semantic-version bump is implied by this Unreleased section.
