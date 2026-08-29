# Admin Audit release integration

Goal: carry validated PR #31 audit behavior onto PR #30 release candidate without losing Health/Accessibility/Activity/Favorites/Preview/Quick Equip work.
Allowed paths: audit service/hooks/component/spec/QUnit, admin catalog template, accessibility stylesheet, plugin wiring, runtime trigger, this packet.
Relevant context: base `f328fbfd68ab612e3f86232d3669b015b5e264a2`; source audit `09b97c7a8ed0fd3e3969387bb5f2f465c2f5b631`; Base runtime `8ba41ad7550c4f2001a7a125a3b5370b342f9b97`.
Acceptance: successful Store admin mutations create whitelist-only StaffActionLogger rows; rejected mutations do not; admin panel remains read-only/searchable; existing Health panel remains intact.
Validation: exact diff, Official Discourse Plugin CI, pinned two-plugin runtime on the exact integration head.
Risk: T2 because wallet/manual-refund admin actions are observed; audit must not expose free-form reasons, provider refs/secrets, callback payloads, or alter financial truth.
Escalation trigger: any audit hook changes wallet/refund semantics, authorization, schema, provider calls, or source behavior beyond integration conflict resolution.
Merge: prohibited until explicit user authorization.