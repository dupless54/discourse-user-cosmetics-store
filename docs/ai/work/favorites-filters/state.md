# State

- Branch: `feature/cosmetics-favorites-filters`.
- Parent: `feature/cosmetics-rarity-limited-seasonal`.
- Existing Favorite model and favorite/unfavorite endpoints remain authoritative and unchanged.
- `/store/favorites` now owns a dedicated client page using the existing catalog payload.
- Filters: search, product type, cosmetic kind, rarity, sale status, tag, affordability, ownership, and sorting.
- Filter/sort logic lives in a reusable pure helper and always scopes this page to `favorite: true` products.
- No schema, Base contract, wallet, purchase, gift, payment, refund, or entitlement changes.
- Merge prohibited without explicit user authorization.
