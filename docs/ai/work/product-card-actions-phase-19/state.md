# Phase 19 — native product-card secondary actions

Goal: move standard product-card favorite and gift controls to current Discourse `DButton` without changing product-card behavior or visual hierarchy.
Allowed paths: product-card component, its focused QUnit test, and this task packet.
Relevant context: current Discourse core `frontend/discourse/app/ui-kit/d-button.gts` supports `@action`, `@actionParam`, `@icon`, translated aria labels, pressed state, disabled state, and normal HTML attributes.
Acceptance: favorite/gift remain icon actions; labels, disabled state, favorite pressed state, callbacks, product open/buy/info rich controls, purchase/gift/favorite semantics, and responsive CSS contracts remain unchanged.
Validation: focused QUnit coverage plus exact changed-path validation; latest exact PR head must pass `Discourse Plugin` and `Cosmetics Integration Runtime Test` before merge.
Risk: frontend-only, no financial/server state mutation changes.
Effort tier: T1.
Escalation trigger: any required stylesheet contract, endpoint payload, wallet/payment behavior, or product-state semantic change.
