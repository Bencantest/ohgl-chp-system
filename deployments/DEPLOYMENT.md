# Deployment Guide

## Local Deployment

1. Configure `config.js` from `config.example.js` or use local environment tooling.
2. Serve the repository root with a static web server.
3. Open `index.html` through the server URL.
4. Use a development Supabase project.

Example:

```bash
python -m http.server 8765 --bind 127.0.0.1
```

## Supabase Deployment

1. Create or select the target Supabase project.
2. Apply migrations in order from `supabase/migrations/`.
3. Verify RLS policies, grants, and secure views.
4. Bootstrap or approve the initial super admin.
5. Run the database verification checklist.

## GitHub Deployment

1. Require CI checks on pull requests.
2. Merge only reviewed branches.
3. Tag release commits.
4. Trigger hosting deployment from protected branches.

## Vercel Deployment

1. Create a Vercel project from this repository.
2. Use the repository root as the static output source.
3. Configure environment-specific `config.js` handling according to deployment policy.
4. Ensure HTTPS is enabled.
5. Run smoke tests after deployment.

## Production Release Process

1. Confirm scope and release notes.
2. Confirm backup completion.
3. Apply staging deployment and run regression tests.
4. Tag release candidate.
5. Apply production migrations.
6. Deploy frontend.
7. Run post-deployment checks.
8. Monitor logs and user reports.

## Rollback Process

- Frontend rollback: redeploy previous tagged static artifact.
- Database rollback: prefer forward-fix migrations. Use rollback scripts only when approved and rehearsed.
- Incident rollback: freeze writes if data integrity is at risk, preserve audit evidence, and document actions.

## Version Tagging Strategy

Use tags such as `ochp-003.0.0`, `ochp-003.0.1-hotfix`, or sprint completion tags documented in the contributor guide.

## Release Checklist

- [ ] CI passed.
- [ ] Required documentation updated.
- [ ] Migrations reviewed and ordered.
- [ ] Backup verified.
- [ ] Staging tested.
- [ ] Release tag created.
- [ ] Production smoke test completed.
- [ ] Rollback owner assigned.
