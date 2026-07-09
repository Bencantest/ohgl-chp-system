# ADR-001 Identity & Access Architecture

## Status

Accepted

## Context

OCHP requires authenticated access for CHPs, facility users, and administrators while preserving facility scope and auditability.

## Decision

Use Supabase Auth for identity and public.users for application profiles, roles, lifecycle state, and facility assignment.

## Rationale

Separating authentication from application authorization keeps credential handling delegated to Supabase while allowing OCHP-specific approval and facility rules.

## Consequences

Every auth user must have a profile. Access decisions depend on profile state as well as session state.

## Alternatives Considered

Application-only passwords; external IAM-only roles; anonymous facility codes.

## Related ADRs

ADR-002, ADR-003, ADR-014
