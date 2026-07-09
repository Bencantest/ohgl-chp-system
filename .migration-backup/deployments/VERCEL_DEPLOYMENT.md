# Vercel Deployment Guide

## Purpose

Deploy the OCHP static frontend without changing application behavior.

## Project Settings

| Setting | Value |
| --- | --- |
| Framework preset | Other or static |
| Output | Repository root/static files |
| Build command | None required for static hosting; CI must run `npm run verify:build` before deployment. |
| Install command | `npm ci` in CI validation. |
| Required files | `index.html`, `config.js`, `src/**`, `vercel.json` |

## Environment Configuration

1. Generate environment-specific `config.js` during deployment or manage it through the hosting policy.
2. Set only browser-safe values: `OHGL_SUPABASE_URL` and `OHGL_SUPABASE_ANON_KEY`.
3. Never expose Supabase service-role keys in Vercel or frontend assets.

## Deployment Steps

1. Confirm CI is green on the release commit.
2. Confirm `vercel.json` security headers are present.
3. Deploy staging first.
4. Run frontend smoke tests.
5. Promote the same commit/tag to production.
6. Record deployment URL, commit, operator, and timestamp.

## Post-Deployment Checks

- Load `index.html` over HTTPS.
- Confirm security headers in browser dev tools or `curl -I`.
- Confirm Supabase requests target the correct environment.
- Sign in as Super Admin.
- Load Settings, Dashboard, Referral pages, and Audit page according to role permissions.

## Rollback

Redeploy the previous known-good Vercel deployment or production tag. If database migrations were also applied, follow `ROLLBACK_CHECKLIST.md` before deciding between forward fix and restore.
