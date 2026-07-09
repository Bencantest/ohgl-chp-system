# Deployment Operations

## Purpose

This document summarizes OCHP operational deployment controls and points to the detailed runbooks in `deployments/`, `docs/database/`, and `docs/operations/`.

## Required Gates

- GitHub Actions CI is green.
- Documentation and migration validation pass.
- Static build verification passes.
- Staging smoke tests pass.
- Production backup is verified.
- Rollback owner is assigned.

## Operational Ownership

| Area | Owner |
| --- | --- |
| Frontend deployment | Release operator |
| Supabase migrations | Database operator |
| Incident decisions | Incident lead |
| Stakeholder updates | Communications owner |
| Verification | Release reviewer |

## Deployment Evidence

Record the following for every production deployment:

- Release version/tag.
- Commit SHA.
- Migration filenames applied.
- Backup timestamp.
- Vercel deployment URL.
- Supabase project reference.
- Smoke test results.
- Operator and reviewer.

## Monitoring Window

Monitor for at least 30 minutes after normal releases and at least 60 minutes after database migrations or hotfixes.

## Rollback Decision

Rollback when production impact is severe, the previous artifact is known-good, and rollback risk is lower than forward fix. Use forward fix for database issues when data integrity can be preserved.
