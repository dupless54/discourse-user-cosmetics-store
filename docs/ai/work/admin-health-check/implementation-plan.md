# Admin Health Check — implementation plan

Goal: add a read-only admin health summary for the cosmetics Store without introducing repair/mutation actions.

Allowed paths: a small Store health service, admin index serialization, admin-only frontend component/template/styles, request/unit tests, task docs, and required plugin require/asset registration.

Checks:
- Store enabled state;
- Base plugin models loaded;
- official Base Integration contract ready;
- Preview Studio contract ready;
- Loadout contract ready;
- enabled catalog products with no cosmetic items;
- enabled catalog products referencing disabled Base cosmetics;
- invalid persisted availability windows;
- configured payment-provider count only (never credentials/secrets).

Acceptance: admin sees overall healthy/warning/critical state and individual checks; endpoint remains admin-only; health is observational only.

No schema, repair endpoint, payment mutation, wallet mutation, ownership or entitlement changes.
Validation: Store RSpec + admin render/QUnit where practical + Official Discourse Plugin CI; pinned two-plugin runtime because Base contract readiness is reported.
Risk: T1/T2 read-only diagnostics.
