# Initial Deployment Checklist

## Before Deployment

- [ ] Production Supabase project created.
- [ ] Production Vercel project created.
- [ ] `OHGL_SUPABASE_URL` and `OHGL_SUPABASE_ANON_KEY` configured for production.
- [ ] Service-role key is not present in frontend config or repository.
- [ ] Migrations validated with `npm run validate:migrations`.
- [ ] CI passed on deployment commit.
- [ ] Initial Super Admin bootstrap plan approved.
- [ ] Backup policy enabled.
- [ ] Incident and rollback owners named.

## Deployment

- [ ] Apply Supabase migrations in order.
- [ ] Deploy frontend static files.
- [ ] Verify security headers.
- [ ] Bootstrap or approve Super Admin.
- [ ] Run smoke tests.

## After Deployment

- [ ] Confirm auth login works.
- [ ] Confirm pending approval queue works.
- [ ] Confirm referral creation works for approved CHP.
- [ ] Confirm workflow actions load.
- [ ] Confirm audit logs record key actions.
- [ ] Record deployment timestamp, commit, and operator.
