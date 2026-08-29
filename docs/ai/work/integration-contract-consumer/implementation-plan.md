# Integration Contract Consumer

Goal: Store'un Base Integration API v1 manifestini tercih etmesi ve eski Base sürümlerinde güvenli legacy fallback'i koruması.
Allowed paths: `lib/discourse_cosmetics_store/base_contract.rb`, Preview/Loadout controllers, Health Check/admin health UI, ilgili specs/QUnit, pinned integration runtime workflow, bu task packet.
Relevant context: Store -> Base dependency direction değişmez; Base PR #46 exact candidate `8c7f0a0b5ee2c66e5f3f0c6e317f1d69ec3cef33`; parent Store exact head `09b97c7a8ed0fd3e3969387bb5f2f465c2f5b631`.
Acceptance: Manifest v1 desteklenir; unknown/malformed manifest capability sağlamaz; manifest yoksa legacy method probes çalışır; Preview/Loadout tek adapter üzerinden gate edilir; Health contract mode/version gösterir; satın alma/cüzdan/ödeme davranışı değişmez.
Validation: Store exact-head Official Discourse Plugin CI + pinned Base/Store runtime; runtime Base PR #46 exact SHA'yı checkout eder ve manifest/capability contractını doğrular.
Risk: Public API/cross-plugin compatibility; no schema/payment/refund/persistence changes.
Effort tier: T2.
Escalation trigger: Base manifest semantiği ile Store legacy fallback arasında davranış çatışması veya pinned runtime failure.
