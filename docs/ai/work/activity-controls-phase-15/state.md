# Phase 15 — Discourse-native Activity controls

## Goal
Modernize the public Store Activity page interaction primitives without changing server-provided activity, wallet, purchase, gift, or Orb semantics.

## Allowed paths
- `assets/javascripts/discourse/components/cosmetics-store-activity.gjs`
- `test/javascripts/components/cosmetics-store-activity-test.gjs`
- this task packet

## Changes
- replace raw Store, Inventory, and sign-in links with current Discourse `DButton`
- replace raw Activity filter buttons with `DButton`
- expose the selected filter with native `aria-pressed` semantics
- preserve timeline rendering, amount/date formatting, and server payload filtering behavior

## Out of scope
- activity endpoints or serializers
- wallet, purchase, gift, refund, mission, or Orb behavior
- models, services, controllers, schemas, migrations, stylesheets, and locales

## Acceptance
- Activity navigation remains reachable
- All/Purchases/Gifts/Orbs filters retain the same visible-event behavior
- selected filter exposes `aria-pressed=true`, inactive filters expose `false`
- logged-out viewers still see only the sign-in state

## Merge gate
Validate exact changed paths, then require Official `Discourse Plugin` CI and `Cosmetics Integration Runtime Test` GREEN on the latest exact PR head SHA. Any new commit invalidates older CI evidence.
