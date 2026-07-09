# ADR-015 Backward Compatibility Strategy

## Status

Accepted

## Context

Existing dashboards, reports, exports, and legacy fields must remain usable while canonical workflow architecture evolves.

## Decision

Preserve legacy fields, compatibility views, and secure full-update paths while shifting authoritative behavior to canonical fields and command RPCs.

## Rationale

Healthcare deployments need continuity and migration windows.

## Consequences

Some duplication exists temporarily. Deprecations must be documented before removal.

## Alternatives Considered

Immediate breaking migration; maintain legacy system indefinitely; fork reports per schema generation.

## Related ADRs

ADR-005, ADR-007, ADR-012
