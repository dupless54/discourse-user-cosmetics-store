# Store Activity Center state

Branch: `feature/store-activity-center`
Base: PR #23 release-candidate head `78b3420d60106a5489034c5a9580069488897d9e`.
Status: implementation complete; exact-head validation pending after this checkpoint commit.
Surface: private read-only `/store/activity` + `/cosmetics-store/activity.json`, Community sidebar link, EN/TR UI, responsive timeline.
Privacy: current-user scoped; no payment capabilities, idempotency keys, provider payloads, ledger reasons, admin notes, emails, addresses, or other-user financial state serialized.
Projection: purchases/gifts are first-class events; purchase/gift ledger rows are suppressed to avoid duplicates; received gifts do not expose sender spend.
Tests: request isolation/projection/sensitive-field coverage + activity component QUnit.
Runtime: pinned User Cosmetics candidate remains `8ba41ad7550c4f2001a7a125a3b5370b342f9b97`.
Merge: not authorized; keep PR stacked on PR #23 and unmerged until explicit user instruction.