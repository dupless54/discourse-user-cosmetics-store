<p align="center">
  <a href="https://buymeacoffee.com/erespawn">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" width="217" height="60">
  </a>
</p>

# Discourse User Cosmetics Store

A native Discourse storefront and Orb economy for [`discourse-user-cosmetics`](https://github.com/dupless54/discourse-user-cosmetics).

The Store does not duplicate cosmetic ownership. Products and bundles reference the base cosmetics catalog, and successful purchases or gifts grant ownership through the User Cosmetics integration contract.

## Current Store Experience

- Responsive `/store` storefront with featured products, editor selections, bundles, collections, rarity metadata, and limited/seasonal presentation.
- Browse and filtering by product metadata, type, rarity, tags, price, and ownership state.
- **Inventory** for owned and unlocked cosmetics.
- **Loadouts** for saved cosmetic sets.
- **Preview Studio** for trying complete cosmetic combinations before applying them.
- **Collections** for grouping themed products under dedicated URLs.
- **Favorites** and quick-access product controls.
- **Quick Equip** for eligible cosmetics.
- **Activity Center** combining purchase, gift, and Orb history in one user-facing timeline.
- Gift notifications routed back to the Activity Center.
- Responsive product dialogs and live cosmetic previews.
- Accessibility and reduced-motion support.
- Administrator health and audit tooling.

## Store Routes

- `/store` — storefront
- `/store/browse` — browse and filters
- `/store/collections` — collections
- `/store/orbs` — Orb wallet/top-up experience
- `/store/favorites` — favorites
- `/store/inventory` — cosmetics inventory
- `/store/loadouts` — saved cosmetic sets
- `/store/preview` — Preview Studio
- `/store/activity` — purchase, gift, and Orb activity

The former duplicate `/store/history` user interface was removed. The compatibility route now redirects users to the single `/store/activity` history surface.

## Orb Economy

- Server-authoritative Orb wallet and immutable ledger entries.
- Idempotent purchases, gifts, mission rewards, payment fulfillment, and refund reconciliation.
- Single cosmetics and multi-item bundles.
- Server-validated one-time mission rewards based on Discourse activity/account state.
- Row locking and idempotency protection against double-clicks and concurrent requests.
- Refund debt handling when previously credited Orbs have already been spent.

## Payment Providers

Optional real-money Orb top-ups can be configured for:

- Stripe
- PayPal
- PayTR
- iyzico
- Shopier, including modern webhook and legacy OSB flows
- Shipy

Payment credentials remain server-side. Provider callbacks/webhooks are treated as untrusted until the configured provider-specific signature, token, amount, currency, identity, and replay checks succeed.

The plugin never trusts client-supplied payment state to credit Orbs or grant cosmetics.

## Completed Roadmap Highlights

The merged Store roadmap on `main` includes:

- Inventory and Collections.
- Cosmetic Loadout Manager.
- Live Preview Studio.
- Rarity and limited/seasonal storefront presentation.
- Favorites and advanced filters.
- Quick Equip.
- Unified Activity/History experience.
- Gift Notifications.
- Accessibility and reduced-motion improvements.
- Admin Health and Admin Audit tooling.
- Versioned User Cosmetics integration-contract consumption.
- Mobile/responsive and Browse-menu fixes.
- Exact-head Cosmetics Integration Runtime Test as a main PR gate.

See [`CHANGELOG.md`](CHANGELOG.md) for the detailed merged roadmap record.

## In Progress — Not Yet on `main`

PR #47, **Storefront hierarchy and responsive layout polish**, is currently open. It focuses on the Preview Studio stacking issue, cleaner page hierarchy, long-text/grid overflow protection, safe-area handling, and stronger 800/600/520/390 px responsive behavior. Treat those visual changes as in progress until the PR is merged.

## Installation

Install the base cosmetics plugin first, then the Store:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dupless54/discourse-user-cosmetics.git
          - git clone https://github.com/dupless54/discourse-user-cosmetics-store.git
```

Rebuild Discourse:

```bash
cd /var/discourse
./launcher rebuild app
```

After the rebuild, enable and configure the Store under the Discourse plugin settings. Keep real-money payments disabled until a provider has been configured and tested in its sandbox/test environment.

## Architecture and Security

Dependency direction is **Store → User Cosmetics**. Cosmetic ownership and entitlement remain authoritative in the base plugin; wallet, ledger, payment, refund, and Store transaction state remain authoritative in the Store.

Financial and provider code is security-sensitive. Preserve atomic balance changes, durable audit records, replay protection, bounded provider requests, and server-side authorization when extending the plugin.

For repository-specific development rules, start with [`AGENTS.md`](AGENTS.md).

## Support

If the Store is useful to your community, you can support continued development through the Buy Me a Coffee banner at the top of this README.
