# Validation commands

Run from a Discourse checkout with this repository installed under `plugins/discourse-user-cosmetics-store`.

## Targeted first
- One Ruby spec, when present: `LOAD_PLUGINS=1 bin/rspec plugins/discourse-user-cosmetics-store/spec/path/to/example_spec.rb`
- Plugin Ruby specs: `bundle exec rake "plugin:spec[discourse-user-cosmetics-store]"`
- Plugin QUnit, when frontend tests are relevant: `CI=1 bundle exec rake "plugin:qunit[discourse-user-cosmetics-store]"`
- After plugin migration changes: `LOAD_PLUGINS=1 bundle exec rake db:migrate`

## CI source
`.github/workflows/discourse-plugin.yml` delegates to the reusable Discourse plugin CI workflow. Treat only the workflow result for the latest exact head SHA as CI evidence.

## High-risk validation
For payment/refund/ledger changes, start with the narrowest affected service/request specs and include duplicate/replay/failure behavior before broader plugin specs. Never weaken assertions merely to get GREEN.
