# Database Guidelines

## Naming Conventions

- Tables use plural snake_case names: `referrals`, `referral_events`.
- Enum types use singular domain names: `referral_stage`, `referral_outcome`.
- Secure RPCs end with `_secure` when they enforce access and business rules.
- Compatibility views use descriptive names such as `referrals_secure` and `chp_directory_secure`.
- Foreign keys use `{entity}_id` naming.

## Migration Strategy

Migrations are forward-only. Each migration should be additive or include an explicit compatibility strategy. Rollback files are operational aids, not a substitute for forward recovery.

## Forward-Only Migrations

Preferred changes:

- Add columns with defaults or nullable compatibility.
- Add new tables and indexes.
- Add new RPCs or replace existing RPC definitions compatibly.
- Backfill data safely.

Avoid:

- Dropping columns used by frontend or reports.
- Renaming tables without compatibility views.
- Rewriting clinical history.

## Enum Conventions

Enums are used for stable domain states such as referral status, stage, owner type, note type, and outcome. Add enum values only when the lifecycle meaning is clear and documented.

## Foreign Key Rules

Use foreign keys for domain relationships. Prefer `ON DELETE SET NULL` for actor references to preserve history and `ON DELETE CASCADE` for child artifacts that should not exist without the parent referral.

## Index Strategy

Indexes should support facility scope, workflow queues, audit timelines, status filters, active department lookup, and notification reads. Add indexes with names that describe table and leading columns.

## Audit Strategy

Administrative and workflow mutations should write audit records. Clinical/workflow timelines should use append-only event records. Actor references should tolerate deleted/deactivated users by preserving historical text/context where possible.

## Soft Delete Policy

Clinical and audit artifacts should not be hard deleted in normal workflows. Archive and lifecycle state should be preferred over deletion for referrals. Directory/admin records may have deactivation states where appropriate.

## Versioning Policy

Clinical notes are versioned. New versions should reference previous notes rather than overwriting content. Metadata contracts should be extended compatibly.

## Backward Compatibility Policy

Legacy fields remain until all dashboards, reports, exports, and external users have migrated. New canonical fields should be authoritative while compatibility fields/views keep older surfaces functional.
