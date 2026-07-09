# ADR-014 Security & RLS Strategy

## Status

Accepted

## Context

OCHP handles sensitive healthcare and identity data in a browser-accessible application.

## Decision

Use RLS, secure views, explicit grants, permission functions, and secure RPCs as layered controls.

## Rationale

Layered database-enforced security reduces reliance on frontend behavior.

## Consequences

Schema changes must consider policies and grants. Tests must include cross-role and cross-facility checks.

## Alternatives Considered

Frontend-only authorization; service key in middleware only; all access through unrestricted views.

## Related ADRs

ADR-001, ADR-002, ADR-004
