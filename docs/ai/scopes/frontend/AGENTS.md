# Cosmetics Store frontend

Apply the frontend sections of `docs/ai/DISCOURSE_DEVELOPER_BASELINE.md` before introducing a new Discourse integration pattern.

- Client consumes server catalog/wallet/payment APIs; it never calculates authoritative balances, ownership, fulfillment, or refund state.
- Treat payment tokens as sensitive capabilities; do not persist/log them unnecessarily.
- Handle pending/success/failure/refund states explicitly and tolerate retries/reloads.
- Prefer modern Glimmer `.gjs`; use `.gts`/TypeScript when complex state or payload contracts benefit from type checking. Inject services with `@service` instead of deprecated ownership helpers.
- Prefer Discourse UI-kit primitives over custom infrastructure: `DModal` for dialogs, `DButton` for actions, and FormKit (`Form`, `field.Control`, validation/actions) for production forms where applicable.
- Extension priority is supported Plugin API/UI-kit -> Transformer -> Plugin Outlet -> narrowly scoped `modifyClass`. Full core-template overrides are exceptional and require a documented reason.
- Use `lib/viewport` for viewport behavior and `lib/container` when the component must respond to its own width. Avoid adding arbitrary raw breakpoints unless a documented physical constraint requires one.
- Do not use `.mobile-view` / `.desktop-view` as the primary responsive architecture. Touch and hover are capabilities: hover may enhance UX but every action must remain reachable by tap/click/focus.
- Use BEM-style scoped `cstore-*` classes and Discourse/core CSS variables. Avoid global CSS leakage and broad core overrides.
- Keep locale-backed copy, safe escaping, keyboard/focus usability, reduced-motion behavior, and light/dark/narrow-phone/tablet compatibility.
- For drag/resize/gesture interactions use current Discourse primitives when available and provide a keyboard-accessible alternative.
- Add QUnit component/acceptance tests for meaningful behavior and system specs when real browser integration/layout matters. Do not add arbitrary sleeps; wait on observable state.
- Do not couple directly to base plugin internals when existing Store APIs provide the needed surface.
