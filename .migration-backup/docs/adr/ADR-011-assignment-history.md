# ADR-011 Assignment History

## Status

Accepted

## Context

Referral ownership changes need traceability for clinical responsibility and operational review.

## Decision

Write referral_assignment_history records whenever owner type, user, facility, or department changes materially.

## Rationale

Assignment history explains workload handoffs and supports accountability.

## Consequences

Assignment commands require reasons. UI should display ownership history read-only.

## Alternatives Considered

Only current owner fields; audit logs only; comments-based assignment tracking.

## Related ADRs

ADR-005, ADR-006, ADR-012
