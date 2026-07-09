# Support Policy

This document defines OCHP product lifecycle stages and support expectations.

## Prototype

Purpose: validate architecture, workflows, and stakeholder needs.

Support level: best effort.

Allowed changes: frequent breaking changes with stakeholder awareness.

Data: synthetic or controlled pilot data only unless approved.

## Pilot

Purpose: limited operational trial in selected facilities.

Support level: active support during agreed windows.

Allowed changes: controlled improvements and bug fixes.

Exit criteria: UAT signoff, stable workflows, production readiness checklist, support process validated.

## Production

Purpose: live operational use.

Support level: formal issue triage, release management, backup/restore procedures, and incident response.

Allowed changes: SemVer-managed releases, hotfixes, and approved enhancements.

## Long-Term Support (LTS)

Purpose: maintain stable deployments for organizations that cannot upgrade frequently.

Support level: security fixes, critical bug fixes, and compatibility patches.

Feature changes: limited and controlled.

Recommended LTS duration: 12 to 24 months depending on deployment agreement.

## End of Support

A version enters end of support when:

- A replacement version has been available for an agreed period.
- Security or platform dependencies can no longer be maintained safely.
- Stakeholders approve retirement.

Required actions:

- Notify stakeholders.
- Provide migration path.
- Archive documentation.
- Preserve audit and clinical data according to policy.

## Archive

Archived releases remain documented but do not receive fixes. Archive records should include release notes, migration notes, known issues, and support sunset date.

## Severity Levels

Critical: patient safety, data integrity, security exposure, or system unavailability.

High: major workflow blocked with workaround limited or unavailable.

Medium: workflow degraded but workaround exists.

Low: cosmetic, documentation, or minor usability issue.

## Response Targets

Targets depend on support agreement, but production defaults should aim for:

- Critical: same business day acknowledgement.
- High: one business day acknowledgement.
- Medium: next planned patch review.
- Low: backlog triage.
