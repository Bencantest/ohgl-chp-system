# ADR-013 Notification Queue Strategy

## Status

Accepted

## Context

Workflow actions should notify users without coupling command execution to external delivery services.

## Decision

Queue notification intent through notification records/events and leave channel delivery to later consumers.

## Rationale

Decoupling avoids slowing or failing clinical commands because an external provider is unavailable.

## Consequences

Delivery status tracking should be added when provider integrations are implemented.

## Alternatives Considered

Direct SMS from frontend; synchronous provider calls in every command; no notification persistence.

## Related ADRs

ADR-006, ADR-008
