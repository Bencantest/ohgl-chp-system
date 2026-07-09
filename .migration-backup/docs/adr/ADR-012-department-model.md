# ADR-012 Department Model

## Status

Accepted

## Context

Legacy department text fields are insufficient for routing and assignment validation.

## Decision

Add canonical departments per facility while retaining legacy department text for compatibility.

## Rationale

Canonical departments allow validated routing, reference data, and future queues.

## Consequences

New workflow actions should use department_id where possible; legacy reports continue reading department text.

## Alternatives Considered

Global department enum; free-text only; separate department table without facility scope.

## Related ADRs

ADR-005, ADR-011, ADR-015
