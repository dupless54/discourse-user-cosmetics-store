# Implementation plan

Goal: Turn existing rarity and availability metadata into a real limited/seasonal storefront experience without changing ownership semantics.
Allowed paths: Store product model/controller, storefront/admin UI, Store styles/locales/tests, task packet docs, runtime workflow only if validation needs it.
Relevant context: `Product` already owns rarity, exclusive, `available_from`, `available_until`; purchase/gift services already re-check `available_now?` under lock.
Acceptance: active limited/seasonal badges and remaining-time copy; upcoming products visible in browse but not purchasable/giftable or promoted on home sections; rarity + availability filters; admin clearly surfaces schedule/type; expired products disappear from new-acquisition catalog; owners keep cosmetics usable after season end.
Validation: model/request specs + QUnit + Official Discourse Plugin CI; existing pinned two-plugin runtime remains required because Store still depends on Base.
Risk: T1 overall; T2 only around purchase/gift availability boundary, which must remain server-authoritative and unchanged.
Escalation trigger: any schema change, ownership revocation, wallet semantics change, or need to bypass `available_now?`.