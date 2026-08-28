# Accessibility / Animation — Store implementation plan

Goal: make Store interactions keyboard-visible and respect `prefers-reduced-motion` without changing commerce or entitlement semantics.

Allowed paths: Store frontend helpers/components/styles/tests, plugin asset registration, and this task packet.

Acceptance:
- interactive Store controls retain a visible `:focus-visible` indicator even where older styles suppress outlines;
- hover-only product affordances are also revealed by keyboard focus;
- UI movement/transitions are suppressed when the viewer requests reduced motion;
- profile-effect layers and card-decoration/legacy profile-effect motion previews are not rendered under reduced motion;
- purchase, gift, favorite, wallet, ownership and Base integration behavior remain unchanged.

Validation: Store QUnit + Official Discourse Plugin CI. No schema/migration.
Risk: T1 frontend presentation only.
Escalation: any change to commerce, persistence, entitlement or Base public contracts is out of scope.
