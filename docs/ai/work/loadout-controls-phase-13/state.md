# Loadout controls phase 13

Goal: modernize the public Store loadout action controls with current Discourse UI-kit primitives without changing loadout persistence or atomic apply semantics.

Scope:
- replace raw action/link buttons in the loadout page with `DButton`
- add native `dialog.confirm` before destructive loadout deletion
- preserve the existing create/rename inputs, form submit semantics, responsive layout, routes, request payloads, and server-owned entitlement/apply rules
- update focused QUnit coverage for the native controls and delete confirmation boundary

Out of scope:
- Base plugin loadout implementation
- Store loadout endpoints or authorization
- schema/model/service changes
- cosmetic entitlement rules or atomic apply behavior

Validation: exact-head Official Discourse Plugin CI + Cosmetics Integration Runtime Test GREEN.
Effort tier: T1 UI-only refactor.
