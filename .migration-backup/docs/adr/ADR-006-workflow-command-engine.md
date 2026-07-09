# ADR-006 Workflow Command Engine

## Status

Accepted

## Context

Frontend-driven status changes could bypass lifecycle rules and role restrictions.

## Decision

Implement workflow progression through backend command RPCs that validate permissions, ownership, transitions, payloads, and side effects.

## Rationale

The backend must be the source of truth for referral state transitions.

## Consequences

UI must render and execute available actions rather than choosing next states.

## Alternatives Considered

Editable status dropdowns; frontend transition maps; manual facility updates.

## Related ADRs

ADR-004, ADR-005, ADR-007
