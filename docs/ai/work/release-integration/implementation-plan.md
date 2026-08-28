# Store release integration plan

Goal: combine the already-green Store feature checkpoints into one non-main release candidate and prove they coexist.
Allowed paths: feature-owned Store source/tests/locales/docs plus integration workflow/metadata needed to reconcile PRs #17-#21.
Relevant context: start from PR #21 head `9da2145ef83f62e23cc7f2dddbac0c50037e61aa`; merge behavior from PR #20, then PR #18 (which includes #17); PR #19 is already in the starting ancestry.
Acceptance: Preview, Loadouts, Quick Equip, private History, and Gift Notifications all remain present; no feature loses server authority; existing gift transaction body and wallet/payment/refund behavior remain unchanged.
Validation: exact changed-path review, Official Discourse Plugin CI, pinned two-plugin runtime against the newest Base public-contract candidate that contains loadouts + selection + preview APIs.
Risk: T2 because this reconciles cross-plugin public contracts and a financial-adjacent gift notification hook.
Effort tier: T2 for reconciliation/contract validation; T1 for locale/navigation/test conflict cleanup.
Escalation trigger: any conflict changes gift transaction semantics, wallet/payment/refund behavior, authorization, schema, or Base dependency direction.
Merge policy: integration branch/PR only; never merge to `main` without explicit user authorization.
