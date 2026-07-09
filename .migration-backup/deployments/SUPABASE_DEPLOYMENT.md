# Supabase Deployment Guide

## Purpose

Apply OCHP database changes predictably while protecting RLS, audit trails, IAM, and referral data.

## Pre-Deployment

1. Confirm target project: development, testing, staging, or production.
2. Verify latest backup timestamp.
3. Run `npm run validate:migrations`.
4. Review migration order under `supabase/migrations/`.
5. Confirm no migration modifies healthcare workflow behavior outside approved scope.
6. Confirm rollback or forward-fix owner.

## Migration Execution

1. Apply migrations in filename order.
2. Capture command output and migration IDs.
3. Stop on first failure.
4. Do not retry failed migrations blindly; inspect partial changes first.
5. Record completion timestamp and operator.

## Post-Migration Verification

- Super Admin can list pending users.
- IAM secure RPCs respond only to Super Admin.
- RLS remains enabled on protected tables.
- Referral secure views load for approved users.
- Workflow metadata RPCs are available.
- Audit inserts continue to work.

## Failure Handling

1. Freeze additional deployments.
2. Preserve logs and SQL output.
3. Determine whether the failure happened before or after a transaction boundary.
4. Prefer a forward-fix migration when data is intact.
5. Restore from backup only with incident approval.

## Production Notes

Production migrations require backup verification, release window approval, a named database operator, and a communications owner.
