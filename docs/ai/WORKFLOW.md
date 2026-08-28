# CI-first delivery workflow

Any model may act as Builder. Independent ChatGPT/Codex review, Claude review, and Gemini final verification are optional tools, not default merge gates. Do not wait for an AI reviewer unless the user explicitly requires that reviewer in the current task.

## Mandatory delivery gate
- keep task scope locked
- validate exact changed paths
- run relevant targeted checks when available
- use the latest exact PR head SHA only
- require the official `Discourse Plugin` workflow to conclude GREEN on that exact head
- if GitHub exposes a separate required `Discourse` CI/check context, require it to conclude GREEN too
- never reuse CI evidence from an older head SHA
- `NO_CI`, missing, pending, cancelled, neutral, or failed required checks are not GREEN
- AI reviewer/verifier approval never substitutes for required Discourse CI
- merge still requires explicit user authorization for the current task

## CI failure remediation
If CI fails, inspect the failing job, find the first actionable root cause, classify it as code/test-fixture/dependency/infrastructure, make the smallest justified repair, run targeted validation, push a new head, then evaluate CI again for that new SHA. Never weaken tests or expand product/architecture scope merely to make CI green.

Maximum automatic remediation: 3 repair rounds. After 3 unresolved rounds, or if a material architecture/security/schema/product decision is required, stop with `NEEDS_HUMAN` and report the current head, remaining failure, root cause, attempted repairs, and recommended next action.

If required CI is not configured or does not run, report `NO_CI`/`NOT_RUN`; do not call it GREEN. A human may explicitly override that gate.
