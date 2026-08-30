# Discourse User Cosmetics Store Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Context routing
Current source/tests > `docs/ai/CURRENT_STATE.md` > nearest local `AGENTS.md` > stable docs > plans/history. Read only what the current task needs.

Route by surface:
- controllers/models and store behavior -> `app/AGENTS.md`
- wallet/purchase/gift/payment/refund/provider services -> `lib/AGENTS.md`
- admin UI/API -> `admin/AGENTS.md`
- client storefront -> `docs/ai/scopes/frontend/AGENTS.md`
- migrations/schema -> `db/AGENTS.md`
For multi-session work use the minimal `docs/ai/work/<feature>/{state.md,progress.md,implementation-plan.md}` packet.

## Fast task path
For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only for validation, and `DECISIONS.md` only for architecture/payment/dependency choices. Skip the formal packet for trivial one-file edits.

## Financial and dependency invariants
This plugin owns Orbs wallet/ledger, products, purchases, gifts, missions, favorites, orb packages, payment lifecycle, fulfillment, refunds, and payment-event audit. It consumes `discourse-user-cosmetics` as the base cosmetic catalog/ownership plugin.

- Dependency direction is Store -> User Cosmetics; do not make the base plugin depend on Store without explicit architecture approval.
- Wallet/ledger balance changes require atomicity, replay safety, and durable auditability.
- Purchases, fulfillment, refunds, callbacks, and webhooks must be idempotent against retries/duplicates.
- Never trust a provider callback without the existing provider-specific signature/token/credential validation.
- Never credit Orbs or grant cosmetics from client-supplied payment state.
- Refund behavior must prevent retained spendable credit or duplicate reversals and must preserve an auditable event trail.
- External provider requests require bounded timeouts/error handling; never log secrets or sensitive callback payloads blindly.
- Existing filtered fields/credentials/PII remain secret: payment provider keys, webhook secrets, identity data, address, phone, and related values.
- Admin wallet adjustment, catalog mutation, package management, and refund actions remain admin-authorized.

## Implementation and tests
Use current Discourse APIs verified from source. Keep business rules server-side and changes small. Payment/schema/security work is high risk: read the relevant schema/security skill before changing it. Test happy path plus replay/duplicate/failure/authorization and partial-failure behavior relevant to the change. Never claim unrun tests passed.

Stop for unresolved financial semantics, refund policy, provider contract, schema/migration, security, or cross-plugin architecture. Preserve unrelated work and `.claude/settings.local.json`. No force-push/reset/clean/branch deletion/deploy/destructive DB work. Prefer targeted symbols/diffs/logs over broad scans. Reusable procedures are under `.agents/skills/` and load on demand; use `task-packet` for non-trivial work.

## CI-only merge gate
Claude/Gemini/Codex reviewer or verifier approval is not required and must never block merge. Do not request or wait for AI approvals as a merge condition.

For a normal scoped PR, the merge gate is CI only:
- validate the exact changed paths still match the task;
- use only the latest exact PR head SHA;
- require the official `Discourse Plugin` CI workflow on that exact head to conclude GREEN;
- if the repository exposes any additional required Discourse-owned CI/check context, it must also be GREEN;
- a new commit invalidates all older CI evidence;
- `NO_CI`, missing, skipped, pending, cancelled, neutral, stale-head, or failed checks are not GREEN.

When the latest exact head is GREEN and no unresolved security/schema/product/architecture blocker remains, the agent is pre-authorized to merge without asking for another user confirmation. Prefer squash merge with `expected_head_sha` when supported. Never weaken tests or broaden scope just to obtain GREEN.

## Adaptive model / effort routing
Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, security, or validation to save tokens.

## Live Discourse developer source gate

Canonical live upstream index: https://meta.discourse.org/t/developer-guides-index/308036?tl=en

For any Discourse-version-sensitive implementation, refactor, review, or compatibility decision:
- start at the live Developer Guides Index and open only the task-relevant official topic(s);
- for plugin work prioritize **Code & Internals + Plugins**; for theme work prioritize **Code & Internals + Themes & Components / Theme Developer Tutorial**; use environment/general guides only when relevant;
- verify version-sensitive APIs and deprecations against current `discourse/discourse` core or the current official plugin/theme skeleton before coding when needed;
- current official docs/core beat remembered examples, old snippets, and copied local guidance unless the repo deliberately targets an older validated release via `.discourse-compatibility` / d-compat;
- do not preload the full index: read the nearest local rules and target source/tests first, then fetch only the upstream guide(s) needed for the current choice.
