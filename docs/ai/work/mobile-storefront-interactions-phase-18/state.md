# Phase 18 — mobile storefront interaction regression

Goal: fix screenshot-confirmed mobile Store spacing, overlap, top-up-label and product-dialog interaction/layout regressions.
Allowed: `assets/stylesheets/discourse-cosmetics-store-navigation.scss`, `assets/stylesheets/discourse-cosmetics-store-responsive-native.scss`, `assets/stylesheets/discourse-cosmetics-store-dialog-responsive.scss`, narrowly required storefront component/test files, this packet.
Context: current Discourse responsive guidance uses `lib/viewport`/`lib/container`; DModal owns backdrop/focus/safe-area/viewport behavior.
Acceptance: Store chrome sits directly below header; compact nav does not cover filters/content; Browse dropdown remains tappable; Orb top-up label is visible; product modal controls are tappable/scrollable and preview cannot cover commerce controls; 320–1024px layouts have no horizontal overflow.
Preserve: purchase/gift/payment/wallet/ownership server semantics and payloads, product filtering, desktop behavior.
Validation: focused QUnit regressions + exact changed-path validation + Official Discourse Plugin CI + Cosmetics Integration Runtime Test on latest exact head.
Risk: T2 interaction regression touching purchase/gift UI but no financial business logic.
Escalate only if a fix requires controller/service/payment/schema or Base-plugin contract changes.