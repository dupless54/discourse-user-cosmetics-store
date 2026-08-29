# Favorites + Activity integration task packet

Goal: carry the already validated filterable Favorites Center from PR #24 onto PR #25 without changing backend semantics.
Allowed paths: Favorites component/filter/template, EN/TR client locales, focused QUnit tests, this work packet.
Relevant context: PR #25 exact base `048732ebf813c08d010b87764af615d1a526410e`; PR #24 source head `9d64a76d91a8d1c3685ee4eed5524cb117bd5e23`.
Acceptance: `/store/favorites` renders only saved products, supports search/type/kind/rarity/availability/tag/affordability/ownership filters and sorting, immediate successful unfavorite removal, signed-out/empty/no-match states.
Authority: existing Store catalog payload and favorite/purchase/gift endpoints remain authoritative; client performs no ownership/balance/payment/refund decisions.
Validation: focused QUnit + exact-head Official Discourse Plugin CI; compare exact changed paths before final checkpoint.
Risk: T1 frontend integration. Escalate only if current catalog/API contract diverged, financial semantics appear, or cross-plugin behavior is required.
Merge/deploy: forbidden without separate explicit user authorization.
