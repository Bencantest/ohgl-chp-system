# On-Call Guide

## Responsibilities

- Monitor deployment and production alerts during assigned windows.
- Triage authentication, RPC, database, workflow, and frontend availability issues.
- Escalate SEV1/SEV2 incidents quickly.
- Preserve logs and release evidence.
- Avoid making unreviewed data changes.

## Required Access

- GitHub repository and Actions logs.
- Vercel project dashboard.
- Supabase project dashboard for the assigned environment.
- Release notes and deployment checklists.
- Incident communication channel.

## Common Checks

- Is the correct frontend version deployed?
- Is `config.js` pointing to the expected Supabase project?
- Are Supabase auth/API/database services healthy?
- Are failures isolated to one role or broad?
- Did the issue begin after a deployment or migration?

## Escalation

Escalate immediately for data integrity concerns, RLS/IAM bypass suspicion, production auth outage, or failed restore/migration.

## Handoff

Include current severity, impacted users, timeline, actions taken, logs collected, open decisions, and next update time.
