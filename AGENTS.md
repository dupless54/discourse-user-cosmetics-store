# Discourse User Cosmetics Store Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Context routing
Current source/tests > `docs/ai/CURRENT_STATE.md` > nearest local `AGENTS.md` > stable docs > plans/history. Read only what the current task needs.

Route by surface:
- controllers/models and store behavior -> `app/AGENTS.md`
- wallet/purchase/gift/payment/refund/provider services -> `lib/AGENTS.md`
- admin UI/API -> `admin/AGENTS.md`
- client storefront -> `assets/javascripts/discourse/AGENTS.md`
- migrations/schema -> `db/AGENTS.md`
For multi-session work use the minimal `docs/ai/work/<feature>/{state.md,progress.md,implementation-plan.md}` packet.

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

Stop for unresolved financial semantics, refund policy, provider contract, schema/migration, security, or cross-plugin architecture. Preserve unrelated work and `.claude/settings.local.json`. No force-push/reset/clean/branch deletion/deploy/destructive DB work; remote writes only when explicitly authorized.

Prefer targeted symbols/diffs/logs over broad scans. Reusable procedures are under `.agents/skills/` and load on demand.
