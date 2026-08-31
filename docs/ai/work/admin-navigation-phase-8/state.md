# Phase 8 state — Discourse-native plugin admin navigation

## Base
- `main` at `5866f4944d47213708d1e6d0396a8acd3aec3a73`.
- Current Discourse baseline: `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`.

## Goal
Replace the Store admin page's private in-component tab router with current Discourse plugin-admin routes and top configuration tabs.

## Scope
- keep `use_new_show_route: true` and `admin.adminPlugins.show` as the plugin admin shell;
- expose Overview, Products, Missions, Payments, and Wallets as addressable plugin routes;
- use `DPageSubheader` and `admin-config-page__main-area` for route-level page structure;
- move the admin navigation initializer into the admin JS bundle;
- split the legacy all-in-one admin component into bounded product, mission, payment, and wallet surfaces;
- begin `d-table` adoption on the product list;
- keep all existing admin API endpoints and server authorization unchanged.

## Invariants
No wallet arithmetic, payment/refund semantics, product/mission persistence rules, authorization, routes on the Rails API, schema, or public Store behavior changes.

## Follow-up
Convert the extracted product/mission/payment/wallet forms and remaining custom tables to FormKit, native confirmation/dialog services, locale-backed copy, native empty states, and full `d-table` patterns in focused phases.

## Gate
Merge only after Official Discourse Plugin CI and Cosmetics Integration Runtime Test are GREEN on the latest exact PR head SHA.
