# Store purchase + gift history progress

- Private history API implemented with current-user scoping and no-store caching.
- `/store/history` route, component, EN/TR copy, sidebar link, and inventory cross-link implemented.
- Request coverage added for anonymous privacy, current-user isolation, sent/received counterpart data, and refunded history.
- QUnit coverage added for purchase/sent/received tabs and anonymous login state.
- Branch scope is stacked only on Inventory + Collections checkpoint; no schema or financial mutation paths changed.
- Next: open draft PR, run exact-head Discourse Plugin CI and integration runtime, fix any failures, then record final exact head.
