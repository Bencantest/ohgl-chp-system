# Supported Environments

## Browser Support

| Browser | Support Level | Notes |
| --- | --- | --- |
| Current Chrome/Edge | Supported | Primary desktop validation target. |
| Current Firefox | Supported | Validate core workflows. |
| Current Safari | Supported | Validate login and referral workflows before broad rollout. |
| Mobile browsers | Best effort | Use for review/field access checks; full desktop administration is preferred. |

## Hosting Support

| Component | Supported Platform |
| --- | --- |
| Frontend | Vercel static hosting or equivalent HTTPS static hosting. |
| Database/Auth/API | Supabase managed project. |
| CI | GitHub Actions. |

## Environment Support

| Environment | Support Expectation |
| --- | --- |
| Development | Developer-owned, disposable data. |
| Testing | Automated checks and synthetic data. |
| Staging | Production-like validation. |
| Production | Operationally monitored and backed up. |

## Unsupported Configurations

- Frontend deployments containing service-role keys.
- Shared Supabase projects between production and non-production.
- Production deployments without backup verification.
- Direct database edits outside approved runbooks.
