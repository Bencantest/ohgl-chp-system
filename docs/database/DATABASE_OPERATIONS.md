# Database Operations

## Backup

- Schedule automated Supabase backups according to the production plan.
- Before every production migration, take or verify a recent backup.
- Record backup timestamp, project, and operator in release notes.

## Restore

- Restore first into a non-production project.
- Verify schema, RLS, and critical workflow data.
- Restore production only under incident leadership and with stakeholder communication.

## Migration Deployment

1. Review migration ordering and naming.
2. Run `npm run validate:migrations`.
3. Apply migrations to staging.
4. Run smoke and workflow tests.
5. Apply to production during approved release window.

## Rollback Strategy

OCHP prefers forward-only recovery. Rollback SQL should be treated as an emergency tool and validated before use. Clinical history and audit records should not be destructively removed.

## Disaster Recovery

- Identify incident commander.
- Freeze deployments.
- Preserve logs and audit trails.
- Restore staging from latest backup to assess recovery point.
- Communicate expected recovery time.
- Apply production restore or forward fix.

## Database Verification Checklist

- [ ] Migrations applied in order.
- [ ] RLS enabled on sensitive tables.
- [ ] Secure RPC grants present.
- [ ] Secure views readable by authenticated users.
- [ ] Direct protected table writes revoked where required.
- [ ] Super admin can access IAM.
- [ ] Facility users cannot access other facilities.
- [ ] Referral workflow commands write events and audit logs.

## Pre-Deployment Checklist

- [ ] Backup verified.
- [ ] Staging migration tested.
- [ ] Release notes ready.
- [ ] Rollback plan approved.
- [ ] Maintenance window communicated.

## Post-Deployment Checklist

- [ ] Login works.
- [ ] New user registration works.
- [ ] Approval workflow works.
- [ ] Referral creation works.
- [ ] Workflow actions load.
- [ ] Reports and dashboards load.
- [ ] Audit logs record actions.
