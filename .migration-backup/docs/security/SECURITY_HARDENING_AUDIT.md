# Security Hardening Audit

Date: 2026-07-05

Scope: authentication, authorization, RLS, secure RPCs, database privileges, secrets, dependencies, headers, logging, auditability, and healthcare compliance posture.

## Executive Summary

OCHP has a strong security foundation: Supabase Auth, profile lifecycle enforcement, canonical roles, permission tables, RLS, secure RPCs, workflow command validation, audit logs, and security headers. The highest-priority remaining work is operational: server-side rate limiting, MFA policy, live RLS penetration tests, dependency monitoring, production secret rotation procedures, and formal compliance mapping.

## Authentication Review

Observed controls:

- Login uses Supabase `signInWithPassword`.
- Registration uses Supabase `signUp` and creates users pending approval through profile reconciliation/provisioning.
- Password reset uses Supabase `resetPasswordForEmail`.
- Session bootstrap loads the app profile and blocks non-approved lifecycle states.
- Logout signs out through Supabase and clears in-memory app state.
- Auth forms include client-side rate limiting for login and registration.

Weaknesses identified:

- Client-side rate limiting is bypassable and should be supplemented with Supabase/provider-side controls.
- MFA is not documented as required for privileged roles.
- Session duration and refresh token policies are inherited from Supabase project settings and need operational documentation.
- Password strength policy depends on Supabase configuration and should be explicitly enforced in project settings.

Recommended improvements:

- Require MFA for `super_admin` and production facility managers.
- Configure Supabase Auth password policy, leaked password protection if available, and email confirmation policy.
- Document session expiry and refresh token settings per environment.
- Add server-side abuse protection or edge/API gateway rate limiting for auth endpoints where available.

## Authorization Review

Observed controls:

- Canonical roles and role permissions exist.
- Frontend page rendering uses role-aware checks.
- Backend secure RPCs enforce permissions and lifecycle/ownership checks.
- User lifecycle states block app access after authentication.
- Facility isolation is enforced through `same_facility`, ownership checks, and secure views/RLS.

Weaknesses identified:

- Frontend rendering is advisory only; this is acceptable because backend controls exist, but future code must not rely on UI hiding.
- Some legacy compatibility RPCs remain and should be reviewed before broad production rollout.

Recommended improvements:

- Maintain live cross-role tests for every release candidate.
- Add a permission matrix to future compliance evidence packs.
- Retire legacy compatibility paths only after dashboards, reports, and exports are migrated.

## RLS Audit

Observed controls:

- IAM tables have RLS enabled.
- Direct writes to users, permissions, role_permissions, and user_access_audit are denied to authenticated users.
- User self-read and super admin access are supported.
- Audit access is super-admin scoped.
- Notifications and referral event policies are facility/user scoped in existing policies.

Issues and observations:

- `permissions` and `role_permissions` are readable by all authenticated users. This is low risk because permissions are not secrets, but it exposes authorization structure.
- Live RLS tests are still needed to prove cross-facility isolation with real users and JWTs.
- Legacy baseline SQL files may contain older policies; production should rely on ordered migrations and final schema verification.

Recommended improvements:

- Add staging RLS tests using multiple users from different facilities.
- Consider restricting permission catalog reads to approved users only.
- Add a release checklist item to verify final effective policies after migration.

## RPC Security Audit

Observed controls:

- SECURITY DEFINER functions generally set `search_path = public`.
- IAM RPCs assert super admin and require reasons for privileged lifecycle changes.
- Workflow RPCs validate permission, owner, facility, transition, department, reason, and outcome where relevant.
- SQL injection exposure is low because functions use typed parameters and static SQL rather than string-concatenated dynamic SQL.

Issues and observations:

- `approve_user_secure` accepts an optional reason and writes it when present; other lifecycle changes require reasons. Consider requiring approval reasons for consistency.
- Metadata RPCs are SECURITY DEFINER and expose reference data scoped by current user/facility; this is acceptable but should be covered by live tests.
- Legacy status update compatibility remains a broader attack surface than pure command-only workflow.

Recommended improvements:

- Require approval reason in `approve_user_secure` in a future migration if operationally acceptable.
- Add automated checks that every SECURITY DEFINER function sets an explicit search path.
- Add live negative tests for metadata reference data scope.

## Database Security

Observed controls:

- Sensitive PHI fields are encrypted/decrypted through controlled paths where implemented.
- Direct referral writes are revoked after workflow command engine migration.
- Secure views are used for decrypted referral and CHP data.
- Grants are explicit for key views and RPCs.

Issues and observations:

- Encryption key management depends on `app.encryption_key` database setting and must be operationally protected.
- `config.js` contains a Supabase anon key. This is public by design, but environment-specific config should be generated during deployment to reduce accidental project coupling.
- Final database privilege audit should be run against the live database, not only source files.

Recommended improvements:

- Document key rotation and emergency re-encryption strategy.
- Verify anon role grants in production after all migrations.
- Confirm service-role keys never appear in frontend, repository, Vercel public config, or logs.

## Secrets and Configuration

Observed controls:

- `.env.example` exists.
- `.gitignore` excludes `.env`, `.env.*`, and local/staging/production config variants.
- `config.example.js` avoids real keys.
- No service-role key pattern was found in frontend code.

Issues and observations:

- Existing `config.js` is committed with a public anon key and project URL. This is not a service secret, but production governance should generate runtime config per environment.

Recommended improvements:

- Move environment-specific config generation into deployment.
- Rotate any key immediately if a service-role key is ever committed.
- Keep `.env.example` as the only committed env file.

## Dependency Audit

Current package dependencies are minimal and there are no declared runtime npm dependencies. Browser libraries are loaded from CDN in `index.html` and constrained by CSP.

Recommended improvements:

- Pin CDN versions and monitor advisories for Supabase JS, DOMPurify, icons, and fonts.
- Add Dependabot or equivalent if npm dependencies are introduced.
- Consider vendoring critical browser dependencies for stricter CSP later.

## Security Headers

Implemented in `vercel.json`:

- Strict-Transport-Security.
- X-Content-Type-Options.
- X-Frame-Options.
- Referrer-Policy.
- Permissions-Policy.
- Content-Security-Policy.
- Cross-Origin-Opener-Policy.
- X-DNS-Prefetch-Control.

Known tradeoff:

- CSP still allows `unsafe-inline` for scripts/styles because the current static app uses inline event handlers and inline styling. Removing this requires a frontend refactor.

## Logging and Audit

Observed audit coverage:

- Login/logout audit attempts exist.
- User lifecycle changes write user access audit records.
- Facility assignment and role changes are audited.
- Workflow actions write referral audit logs and timeline events.
- Assignment history, clinical notes, SLA updates, and notification events are generated by workflow commands.

Potential gaps:

- Failed login attempts are handled by Supabase but not mirrored into application audit logs.
- Password reset requests are not application-audited.
- Metadata reads are not audited; this is acceptable unless future policy requires read audit.

## Compliance Review

OCHP aligns with healthcare security best practices in access control, auditability, least privilege, data minimization direction, encryption direction, session management via Supabase, and change tracking through ADR/release governance.

Future compliance work:

- Map controls to ISO 27001 Annex A.
- Build HIPAA-style administrative, technical, and physical safeguards evidence even if HIPAA is not legally governing.
- Map Kenya Data Protection Act and healthcare data obligations with local counsel.
- Add DPIA/PIA documentation before broad production deployment.
- Define retention schedules for audit logs, clinical notes, and archived referrals.
