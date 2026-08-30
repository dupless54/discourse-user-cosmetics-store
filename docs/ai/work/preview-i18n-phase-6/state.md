# Phase 6 state — cosmetic preview client i18n

## Base

- Built on current `main` after Phase 5 merge.
- Phase 5 merge commit: `dc7e35eab63a5e41038fabae309e00c120fe2625`.

## Official upstream baseline

Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`:

- production-facing plugin copy belongs in plugin client locale files;
- modern GJS components use `i18n` from `discourse-i18n`;
- locale-aware totals pass `{ count: ... }` to Discourse i18n.

## Scope

- localize the preview fallback member label;
- localize the preview user-card label;
- localize bundle item totals with Discourse plural handling;
- preserve preview assets, reduced-motion behavior, effect layering and user-derived labels;
- add focused QUnit coverage for the localized fallback copy.

## Out of scope

The large storefront shell remains a separate phase because it contains substantially more navigation, filter, empty-state, Orb and collection copy.
