# Final Store Release Candidate Progress

- Final Store RC exact head `8d42995f2a16e5628e73f92c5c96b419ff40e14a` passed Official Discourse Plugin CI and pinned Base/Store runtime before the merge phase.
- Base canonical stack is merged to `main`; final Base main is `8c41e4cf072282e5e554a21e815fd1d1567c5a28`.
- Store public Integration consumer and Inventory/Collections are merged to `main`.
- Loadouts were reconciled with the previously merged mobile storefront fix through a two-parent merge; exact conflict-resolved head passed Official CI and pinned runtime before merge.
- Final main bridge preserves current-main mobile and storefront polish styles while carrying the complete final RC descendant stack.
- Final bridge runtime pins actual Base `main` and verifies Integration contract v1, notification bridge, migration, direct RSpec, plugin-task RSpec, and QUnit.
- Remaining gate: exact-head Official Discourse Plugin CI + pinned Base-main/Store runtime on this final bridge, then normal merge to `main` and close carried/superseded source PRs.
