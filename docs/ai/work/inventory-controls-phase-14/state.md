# Inventory controls phase 14

Goal: modernize the public Store Inventory controls with current Discourse UI-kit primitives without changing inventory, entitlement, or equip semantics.

Scope:
- replace raw Inventory navigation links, mode buttons, equip/unequip buttons, and login action with `DButton`
- preserve the existing cosmetic-kind select and responsive layout
- preserve Store inventory endpoints, Base capability checks, server-confirmed equipped state, and notices
- extend focused QUnit coverage for native pressed-state/navigation semantics

Out of scope:
- entitlement rules or Base plugin selection logic
- Store inventory endpoints or authorization
- schema/model/service changes
- inventory filtering behavior or stylesheet redesign

Validation: exact-head Official Discourse Plugin CI + Cosmetics Integration Runtime Test GREEN.
Effort tier: T1 UI-only refactor.
