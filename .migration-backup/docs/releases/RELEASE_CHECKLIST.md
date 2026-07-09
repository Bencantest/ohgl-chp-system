# Release Checklist

Use this checklist for every release candidate and production release.

## Governance

- [ ] Release owner assigned.
- [ ] Version selected according to SemVer.
- [ ] Scope approved.
- [ ] Release notes prepared.
- [ ] Stakeholders informed.

## Architecture

- [ ] Architecture approved.
- [ ] ADRs added or updated for major decisions.
- [ ] Backward compatibility reviewed.
- [ ] No unapproved business workflow changes.

## Database

- [ ] Database migrations reviewed.
- [ ] Migration naming convention validated.
- [ ] Migration order verified.
- [ ] Backup verified.
- [ ] Rollback or forward-fix plan documented.
- [ ] Staging migration completed.

## Testing

- [ ] JavaScript syntax validation passed.
- [ ] Existing validation scripts passed.
- [ ] Unit tests passed.
- [ ] Integration tests passed or exception documented.
- [ ] Workflow tests passed.
- [ ] Regression tests passed.
- [ ] User Acceptance Testing completed.

## Quality and Security

- [ ] No critical defects.
- [ ] No high severity defects without approved waiver.
- [ ] Performance baseline met.
- [ ] Security review passed.
- [ ] RLS/permission-sensitive changes reviewed.
- [ ] Accessibility smoke check completed.

## Deployment

- [ ] Deployment plan approved.
- [ ] Monitoring configured.
- [ ] Production configuration verified.
- [ ] Release tag prepared.
- [ ] Rollback verified.
- [ ] Post-deployment smoke test owner assigned.

## Production Go-Live

- [ ] Release candidate promoted.
- [ ] Production deployment completed.
- [ ] Post-deployment checklist passed.
- [ ] Support window active.
- [ ] Changelog updated.
