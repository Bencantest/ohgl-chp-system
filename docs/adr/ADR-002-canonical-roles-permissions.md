# ADR-002 Canonical Roles & Permissions

## Status

Accepted

## Context

Legacy role labels existed alongside emerging facility and CHP responsibilities.

## Decision

Normalize roles to canonical values and evaluate fine-grained permissions through role_permissions.

## Rationale

Canonical roles simplify UI and policy logic while permissions allow future module expansion.

## Consequences

Legacy role names need mapping. New modules should add permissions before adding roles.

## Alternatives Considered

Hardcoded role checks only; per-user permissions only; separate role systems per module.

## Related ADRs

ADR-001, ADR-014
