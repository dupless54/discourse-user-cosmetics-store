# Phase 17 — Discourse-native Preview Studio actions

## Goal
Modernize standard Preview Studio navigation and apply/reset actions with current Discourse UI-kit primitives while preserving the custom cosmetic-choice cards and preview/apply behavior.

## Allowed paths
- `assets/javascripts/discourse/components/cosmetics-store-preview-studio.gjs`
- `test/javascripts/components/cosmetics-store-preview-studio-test.gjs`
- this task packet

## Required changes
- replace Inventory and Loadouts hero links with `DButton`
- replace Apply and Reset standard action buttons with `DButton`
- preserve custom slot choice buttons, `aria-pressed` selection semantics, preview geometry, reduced-motion behavior, and `/cosmetics-store/preview/apply.json` payloads
- preserve existing responsive Preview Studio markup and styles
- extend focused QUnit coverage for native action primitives

## Out of scope
No preview controller, Base plugin selection/entitlement logic, profile-effect geometry, stylesheet, locale, model, service, route, or schema changes.

## Merge gate
Exact changed-path validation plus Official `Discourse Plugin` CI and `Cosmetics Integration Runtime Test` GREEN on the latest exact PR head SHA. Standing user authorization permits merge once both gates are GREEN.
