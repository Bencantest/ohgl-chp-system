# Compliance Roadmap

This roadmap translates OCHP security controls into a longer-term compliance program.

## Current Alignment

- Access control: canonical roles, permissions, lifecycle approval, facility isolation.
- Auditability: user access audit, audit logs, referral events, assignment history, clinical note versioning.
- Data protection: encrypted PHI fields where implemented, secure views, RLS, secure RPCs.
- Change tracking: ADRs, release process, migration validation, CI checks.
- Least privilege: protected direct writes, scoped secure RPCs, RLS policies.

## Recommended Compliance Workstreams

### ISO 27001-style ISMS

- Establish asset inventory.
- Define risk assessment process.
- Maintain access review records.
- Formalize incident response.
- Track supplier and hosting provider responsibilities.

### HIPAA-style Safeguards

Even where HIPAA is not legally governing, its structure is useful:

- Administrative safeguards: policies, training, access reviews, contingency plans.
- Technical safeguards: access control, audit controls, integrity controls, transmission security.
- Physical safeguards: workstation, device, and facility access procedures for deployments.

### Kenya and Local Healthcare Regulation

- Complete a Data Protection Impact Assessment before broad deployment.
- Confirm lawful basis, consent/notice, retention, and data subject rights with local counsel.
- Define county/facility data sharing agreements.

### Evidence Pack

For each production release, retain:

- Release checklist.
- Test evidence.
- Migration evidence.
- Backup verification.
- Security review notes.
- UAT signoff.
- Incident and rollback readiness record.
