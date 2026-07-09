# ADR-007 Workflow Metadata Engine

## Status

Planned/Accepted

## Context

Even after command RPC integration, frontend-specific knowledge of forms, labels, confirmations, and reference data creates drift.

## Decision

Expose action definitions, available actions, validation messages, presentation metadata, and command-specific reference data from backend metadata RPCs.

## Rationale

Backend-owned metadata keeps UI behavior aligned with workflow rules and reduces duplicated business knowledge.

## Consequences

Frontend dialogs become generic metadata renderers. Metadata contracts must remain backward compatible.

## Alternatives Considered

Hardcoded frontend forms; JSON config in frontend; separate metadata service.

## Related ADRs

ADR-006, ADR-004, ADR-015
