# State

- Parent Store PR: #19 `feature/cosmetics-loadouts-ui` at branch point `3bfb305b5c7edde9e9c98cced377b583ca1177d0`.
- Store branch: `feature/cosmetics-live-preview-studio`.
- Base dependency: PR #43 `feature/cosmetics-live-preview-contract`.
- Current pinned Base candidate: `8ba41ad7550c4f2001a7a125a3b5370b342f9b97`; final GREEN still required before Store checkpoint is final.
- Preview page: `/store/preview`.
- JSON facade: `GET /cosmetics-store/preview`, `POST /cosmetics-store/preview/apply`.
- Preview offers only currently entitled Base items and keeps changes local until Apply.
- Final Apply uses only public `DiscourseUserCosmetics::Integration.apply_selections!`.
- No schema, wallet, payment, purchase, gift, refund, or Orb changes.
- Merge is not authorized; keep feature PR draft.
