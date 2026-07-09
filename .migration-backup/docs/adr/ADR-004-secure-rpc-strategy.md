# ADR-004 Secure RPC Strategy

## Status

Accepted

## Context

Direct browser writes to sensitive healthcare tables are risky and difficult to audit consistently.

## Decision

Use SECURITY DEFINER secure RPCs for protected mutations, with RLS and grants limiting direct table writes.

## Rationale

RPCs centralize validation, permission checks, ownership checks, side effects, and audit logging.

## Consequences

Frontend must call services/RPCs rather than updating tables directly. RPC contracts require documentation.

## Alternatives Considered

Direct table updates with frontend checks; REST middleware service; database triggers only.

## Related ADRs

ADR-014, ADR-006, ADR-003
