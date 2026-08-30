# Cosmetics Store admin

Apply the admin/frontend sections of `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md` before introducing custom admin UI infrastructure.

- Admin frontend is UX only; server endpoints remain the authorization boundary.
- Keep admin routes/components aligned with current Discourse admin plugin conventions and current Glimmer/service-injection patterns.
- Prefer Discourse UI-kit and FormKit for dialogs, actions, forms, validation, loading, and error states instead of parallel custom primitives.
- Prefer supported Plugin API/Transformers/Outlets over core overrides; `modifyClass` is a last resort and full core-template overrides require exceptional justification.
- Use Discourse responsive helpers (`lib/viewport` / `lib/container`) and capability-aware touch/hover behavior; hover must never be the only interaction path.
- Never display full secrets, sensitive identity data, raw provider credentials, or unnecessary callback payloads.
- Wallet adjustments/refunds/catalog changes need explicit user intent, clear failure states, and no optimistic client-side financial truth.
- Add focused QUnit coverage for meaningful admin interactions and backend authorization/spec coverage for every privileged mutation.
