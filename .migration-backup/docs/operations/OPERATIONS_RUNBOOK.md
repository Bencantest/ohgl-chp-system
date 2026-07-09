# Operations Runbook

## Purpose

This runbook gives operators a repeatable way to deploy, verify, monitor, and support OCHP production without changing application behavior.

## Daily Checks

- Review Supabase service health.
- Review Vercel deployment status.
- Check failed auth/RPC trends.
- Check recent deployment or incident notes.
- Confirm no unresolved production alerts.

## Weekly Checks

- Verify backups are present.
- Review audit log volume and anomalies.
- Review GitHub Actions failures.
- Check documentation drift after releases.

## Release Window Procedure

1. Confirm release candidate and scope freeze.
2. Confirm backup timestamp.
3. Confirm CI and staging smoke tests.
4. Apply Supabase migrations.
5. Deploy frontend.
6. Run health checks.
7. Monitor for at least 30 minutes after deployment.
8. Record release notes and closeout status.

## Operational Escalation

- Severity 1: production unavailable, data integrity risk, or authentication unavailable.
- Severity 2: core workflow degraded but workaround exists.
- Severity 3: isolated user or report issue.
- Severity 4: documentation or non-production issue.

## Production Smoke Test

- Super Admin login.
- IAM pending queue loads.
- Approved CHP access check.
- Referral creation in approved test path or staging.
- Workflow metadata loads.
- Audit page loads for Super Admin.
- No unexpected browser console errors.

## Change Freeze

During incidents, stop deployments except approved rollback or forward-fix actions. Preserve logs before making changes.
