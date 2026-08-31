# Phase 23 — product modal interaction and mobile layout

Goal: fix the Store product modal appearing inert/dimmed, accidental click-out closure, horizontal overflow, and the squeezed mobile preview/action layout reported from desktop and phone screenshots.
Allowed paths: product dialog component, product-dialog responsive stylesheet, focused dialog QUnit test, and this task packet.
Root cause: the native `DModal` wrapper still used the legacy `.cstore-dialog` custom-shell class, allowing old Store CSS to override core modal geometry/pointer behavior; some responsive rules also depended on ancestry that is lost when DModal portals outside `.cstore-shell`.
Implementation: isolate the wrapper as `.cstore-product-modal`; re-assert Discourse modal content/overlay z-layers; veto click-out dismissal while preserving native close-button/keyboard dismissal; prevent horizontal modal-body overflow; scope responsive rules to the portaled modal; stack preview/details on mobile and keep purchase/gift controls full-width and non-overflowing.
Acceptance: modal content remains interactive; clicking the backdrop does not close the product modal; native close button still works; no horizontal scrollbar is introduced by the product grid; mobile product preview/details/actions render as a single-column sheet with bounded preview width.
Validation: focused QUnit covers real DModal backdrop behavior, internal gift interaction, native close button, isolated wrapper, purchase callback, and gift FormKit flow. Latest exact PR head must pass `Discourse Plugin` and `Cosmetics Integration Runtime Test` before merge.
Risk: frontend-only. No purchase, gift, favorite, entitlement, wallet, payment, route, serializer, model, controller, or schema semantics change.
Effort tier: T1 implementation / T2 validation because the UI contains purchase and gift controls.
Escalation trigger: any required change to server endpoints, purchase/gift payloads, wallet state, entitlement rules, or Discourse core modal internals.
