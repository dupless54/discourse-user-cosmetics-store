# Final Cosmetics Store Release Candidate

Goal: validated Store feature lines into one non-duplicated final candidate before any merge to main.

Sources:
- release parent PR #30 exact head `f328fbfd68ab612e3f86232d3669b015b5e264a2`
- History + Gift Notifications source PR #18 exact head `2ed052917e2e750cf9d3d2799f2ed89c8200a5ed`
- Audit + versioned Base contract source PR #32 exact head `8a90a6a9f346e008f8f9594913c76ace888a79bc`
- pinned Base final contract PR #46 exact head `8c7f0a0b5ee2c66e5f3f0c6e317f1d69ec3cef33`

Included behavior:
- inventory/collections, loadouts, live preview, rarity/limited, favorites, reduced-motion/accessibility
- quick equip, private Store activity, Admin Health
- private purchase/gift history and native best-effort gift notifications
- Admin Audit Log
- versioned Base Integration manifest consumer with legacy fallback and fail-closed invalid-manifest handling

Boundaries:
- no new schema or destructive migration in this integration task
- no payment/refund/wallet transaction semantics changed
- gift notification is emitted only after the gift transaction commits and cannot turn a completed financial operation into an apparent failure
- dependency direction remains Store -> User Cosmetics
- duplicate source/integration PRs are not to be blindly merged after this candidate; they will be classified as carried/superseded during the merge phase

Validation:
1. exact-head Official Discourse Plugin CI
2. pinned two-plugin runtime with Base PR #46 exact SHA
3. runtime must migrate both plugins, verify Integration contract v1/capabilities, run all Store RSpec twice (direct + plugin task), and run Store QUnit
4. no merge until the user starts the sequential merge phase

Effort tier: T2.
Escalation trigger: any behavior conflict between carried sibling features, Base manifest contract mismatch, or a final-RC-only CI failure.
