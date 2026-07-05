# Environment Strategy

OCHP uses three operational environments: development, staging, and production. Each environment must have a distinct Supabase project or database and separate credentials.

## Environment Variables

| Variable | Required | Description |
| --- | --- | --- |
| `OCHP_ENV` | Yes | One of `development`, `staging`, `production`. |
| `OHGL_SUPABASE_URL` | Yes | Supabase project URL. |
| `OHGL_SUPABASE_ANON_KEY` | Yes | Public anon key. Safe for browser use but still environment-specific. |
| `OCHP_LOCAL_PORT` | No | Local static server port. |
| `OCHP_RELEASE_VERSION` | No | Human-readable release version. |
| `OCHP_RELEASE_COMMIT` | No | Git commit for deployed release. |
| `SHA_API_BASE_URL` | No | Future SHA integration endpoint. |
| `DHIS2_API_BASE_URL` | No | Future DHIS2 endpoint. |
| `FHIR_BASE_URL` | No | Future FHIR server endpoint. |
| `NOTIFICATION_PROVIDER` | No | Future notification provider label. |

## Development

Purpose: local implementation and validation.

Guidance:

- Use a non-production Supabase project.
- Seed only synthetic or approved test data.
- Run syntax, docs, migration, and workflow checks before merging.

## Staging

Purpose: production-like release validation.

Guidance:

- Mirror production RLS, roles, and migrations.
- Use realistic but non-live PHI unless explicitly approved.
- Validate deployment, rollback, and end-to-end workflow tests.

## Production

Purpose: live operational use.

Guidance:

- Apply migrations through controlled release windows.
- Verify backups before deployment.
- Keep secrets in the hosting provider or Supabase dashboard, never in Git.
- Tag releases and document post-deployment verification.
