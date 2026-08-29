# Release Candidate Integration

Goal: combine PR #22 rarity/seasonal + Live Preview with PR #20 Inventory Quick Equip on one validated Store branch.
Allowed paths: PR #20 changed paths plus integration task docs; preserve PR #21/#22 behavior on overlapping frontend/locales/plugin/workflow files.
Relevant context: base Store head `4cc0a255a2e47a4aea99063842e7bb35df359aaf`; Quick Equip source head `173491276fd4817e7a8b9f02691050e256783141`; Base runtime candidate remains PR #43.
Acceptance: preview/rarity behavior unchanged; inventory reports equipped state; entitled cosmetics equip/unequip through Base public Integration; all EN/TR copy and navigation coexist.
Validation: exact diff review vs PR #22, focused request/QUnit coverage, Official Discourse Plugin CI, pinned two-plugin runtime.
Risk: cross-plugin selection contract and overlapping frontend/plugin wiring; no wallet/payment/refund/schema changes.
Effort tier: T2 during integration/contract validation, T1 for presentation merge.
Escalation trigger: merge conflict changes authority semantics, Base contract mismatch, or any financial/schema behavior appears.
