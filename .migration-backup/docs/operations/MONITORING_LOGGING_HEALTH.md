# Monitoring, Logging, and Health Checks

## Monitoring Goals

Monitoring must detect application failures, failed RPCs, authentication problems, workflow failures, database errors, and performance degradation without exposing PHI in logs.

## Signals to Monitor

| Area | Signals | Alert Threshold |
| --- | --- | --- |
| Application errors | Browser console errors, failed module loads, CSP violations | New sustained error after deployment. |
| Failed RPCs | 4xx/5xx Supabase RPC responses, permission errors, timeout errors | Spike over baseline or repeated failure on core RPCs. |
| Authentication failures | Login failures, signup errors, approval-blocked users | Sudden increase or confirmed valid users unable to log in. |
| Workflow failures | `get_available_referral_actions`, metadata RPC, command RPC failures | Any production-wide failure. |
| Database errors | Postgres errors, migration failures, RLS denial spikes | Any migration failure or repeated production query errors. |
| Performance | Page load time, Supabase latency, slow dashboard/report queries | Sustained degradation reported by users or measured in logs. |

## Recommended Tooling

- Vercel analytics/logs for frontend deployments, static asset delivery, and edge errors.
- Supabase logs for auth, Postgres, API, and edge/API requests.
- GitHub Actions logs for CI/deployment evidence.
- Browser developer tools for release smoke checks.
- Incident notes stored outside the production application.

## Logging Sources

| Log Source | Contents | Retention Recommendation |
| --- | --- | --- |
| Application logs | Non-sensitive console diagnostics and client errors | 30-90 days in hosting/log platform. |
| Database logs | SQL errors, slow queries, connection issues | 90 days minimum for production. |
| Audit logs | User/system actions in application audit tables | 1 year minimum or according to governance policy. |
| Workflow logs | Referral events, assignment history, workflow command results | Same retention as operational referral records. |
| Deployment logs | CI, migration output, release evidence | Retain for lifetime of supported release plus 1 year. |

## Logging Rules

- Do not log passwords, tokens, service-role keys, PHI, or full patient details.
- Prefer IDs, timestamps, status codes, and non-sensitive error codes.
- Keep temporary debug logs behind localhost/session flags and remove after validation.
- Preserve logs during incidents before redeploying or restoring.

## Health Checks

### Frontend

- Load production URL over HTTPS.
- Confirm `index.html`, `src/main.js`, styles, and logo assets load.
- Confirm security headers are present.
- Confirm no blocking JavaScript errors on initial load.

### Supabase

- Confirm project status is healthy.
- Confirm REST API requests reach the expected project URL.
- Confirm auth service is available.
- Confirm database logs show no current incident.

### Authentication

- Login as Super Admin.
- Register a test CHP in non-production.
- Confirm pending users are blocked from main modules.
- Confirm approved users can access role-permitted pages.

### Database Connectivity

- Load dashboard data.
- Load facility list.
- Load secure referral views.
- Confirm queries use the expected environment.

### RPC Availability

- Verify IAM list/approval RPCs in staging or production smoke account.
- Verify workflow metadata RPCs load.
- Verify referral command RPCs are callable by authorized roles.
- Confirm unauthorized roles receive denial, not broad access.

### Storage

OCHP currently has no required user-upload storage workflow. If storage is enabled later, add checks for bucket policies, upload/download permissions, malware scanning expectations, and retention.
