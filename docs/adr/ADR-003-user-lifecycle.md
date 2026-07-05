# ADR-003 User Lifecycle

## Status

Accepted

## Context

Healthcare access must be approved, suspendable, auditable, and reversible where appropriate.

## Decision

Use explicit approval_status states and secure IAM RPCs for approve, reject, suspend, reactivate, deactivate, facility assignment, and role change.

## Rationale

Lifecycle state is clearer and safer than deleting users or toggling a single active flag.

## Consequences

Login can succeed while app access remains restricted. Admin actions require reason capture and audit.

## Alternatives Considered

Immediate self-service access; hard deletion; manual database changes.

## Related ADRs

ADR-001, ADR-004, ADR-014
