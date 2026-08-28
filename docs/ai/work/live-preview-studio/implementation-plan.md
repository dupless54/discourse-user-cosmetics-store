# Live Preview Studio

Goal: let an authenticated user mix every currently entitled cosmetic in an isolated Discourse-native preview and apply the complete four-slot look only when explicitly requested.

Allowed scope:
- preview Store controller and routes
- preview route/template/component/style
- Inventory/sidebar navigation entry points
- EN/TR copy
- request/QUnit coverage
- pinned two-plugin runtime workflow
- this work packet

Architecture:
- Base remains authoritative for active selections and entitlement.
- Store lists only Base-entitled items through `CosmeticsAccess`.
- Preview changes remain client-local until Apply.
- Apply delegates once to Base public `Integration.apply_selections!`; Store never calls `SelectionService` directly.
- The renderer is isolated and reuses the existing safe Store profile-effect layer primitive instead of attaching portals to the real user card.

Acceptance:
- `/store/preview` is a native route and mobile responsive.
- all four cosmetic kinds can be mixed or cleared temporarily.
- current server selections initialize the preview.
- one complete Apply request atomically changes the real selection.
- an unavailable selected item returns 422 and leaves the prior look unchanged.
- only entitled items are offered by the server.
- light/dark themes inherit Discourse variables.

Validation:
- Base preview contract exact-head Official Discourse CI GREEN.
- Store exact-head Official Discourse Plugin CI GREEN.
- pinned two-plugin runtime GREEN with the exact Base preview contract head.

Risk: public cross-plugin contract + frontend rendering boundary.
Effort: T2 architecture, bounded T1 implementation once contract is fixed.
Escalate if new schema, wallet/payment changes, Base -> Store dependency, client-side entitlement authority, or direct Store access to Base internals is required.
