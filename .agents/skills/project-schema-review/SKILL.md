---
name: project-schema-review
description: Review migrations, indexes, constraints, and stored-data changes for correctness and production safety.
---
# Schema review
Check existing financial rows, null/default/backfill, uniqueness/FKs/checks, replay/idempotency constraints, index usefulness, lock/table-scan risk, rollback/recovery, deploy ordering, and audit retention. Stop for irreversible/ambiguous data decisions. Never execute destructive production operations.
