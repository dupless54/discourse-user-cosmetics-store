# Repository map

Use this to choose paths before searching. Source code remains authoritative if the map becomes stale.

- `plugin.rb` — plugin entrypoint/registration.
- `app/` — store models/controllers/serializers; read `app/AGENTS.md`.
- `lib/` — wallet, purchase, gift, payment, refund, provider services; read `lib/AGENTS.md`.
- `admin/` — admin API/UI surfaces; read `admin/AGENTS.md`.
- `assets/javascripts/discourse/` — storefront/client UI; read local `AGENTS.md`.
- `db/` — migrations/schema/financial integrity; read `db/AGENTS.md`.
- `assets/` — storefront presentation assets.
- `config/` — routes/settings/locales/configuration.
- `.github/workflows/discourse-plugin.yml` — reusable Discourse CI entrypoint.
- `docs/` — AI state/workflow and stable docs; do not preload wholesale.

Fast read order: root `AGENTS.md` -> task packet -> nearest local `AGENTS.md` -> exact symbol/source -> exact test. Load payment/security decisions only when that task surface requires them.
