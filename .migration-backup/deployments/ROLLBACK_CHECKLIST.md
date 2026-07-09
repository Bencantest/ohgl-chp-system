# Rollback Checklist

## Trigger Conditions

- Authentication unavailable.
- Approved users cannot access permitted pages.
- Secure RPCs fail broadly.
- Migration causes data integrity risk.
- Frontend deployment blocks core referral operations.

## Immediate Actions

- [ ] Declare incident lead.
- [ ] Freeze further deployments.
- [ ] Preserve CI, Vercel, Supabase, and browser logs.
- [ ] Identify last known-good frontend tag and database backup.
- [ ] Communicate user impact and expected next update time.

## Frontend Rollback

- [ ] Redeploy previous Vercel deployment or tag.
- [ ] Verify correct `config.js` for production.
- [ ] Run auth, IAM, referral, dashboard, and audit smoke tests.

## Database Recovery

- [ ] Determine whether forward fix is safer than restore.
- [ ] Validate forward-fix SQL in staging before production.
- [ ] If restore is required, restore to staging first and verify RLS/audit integrity.
- [ ] Restore production only under incident command approval.

## Closeout

- [ ] Document root cause.
- [ ] Document data impact.
- [ ] Add prevention action to release checklist.
- [ ] Publish incident summary.
