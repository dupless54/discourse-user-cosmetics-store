# Phase 7 state — availability client i18n

## Base

- Built on current `main` after Phase 6 merge.
- Phase 6 merge commit: `e23ee5e9d421f35b09260b972567a316fe81f1b9`.

## Official upstream baseline

Validated against the current Discourse client-i18n conventions already recorded in this repository and `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`.

## Scope

- move availability badges out of the JavaScript helper into client locales;
- move availability detail copy and abbreviated remaining-time units into client locales;
- keep availability classification/filter semantics unchanged;
- keep deterministic remaining-time calculations unchanged;
- update focused unit coverage to verify English locale output.

## Out of scope

No catalog scheduling, server time, purchase eligibility, pricing, ownership, routing, wallet or payment behavior changes.
