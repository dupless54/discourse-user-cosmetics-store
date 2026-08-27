# Cosmetics Store schema
Read `.agents/skills/project-schema-review/SKILL.md` before schema/index changes. Financial tables require careful uniqueness/idempotency constraints, existing-row/backfill behavior, lock/index cost, FK/delete semantics, audit retention, deploy ordering, and recovery. Never destructively rewrite production wallet/payment history.
