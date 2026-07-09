# ADR-010 SLA Tracking Model

## Status

Accepted

## Context

Referral workflows need time-bound monitoring for receiving, treatment, closure, and escalation.

## Decision

Represent SLA timers as referral-linked records with target, warning, breach, completion, pause/resume, and metadata fields.

## Rationale

Dedicated timers support operational reporting without overloading referral status.

## Consequences

SLA policies can evolve independently. Commands must update relevant timers.

## Alternatives Considered

Computed-only SLA from timestamps; one SLA field on referral; external monitoring only.

## Related ADRs

ADR-005, ADR-006, ADR-008
