# ADR-008 Event-Driven Referral Timeline

## Status

Accepted

## Context

Referral history must be immutable and explain who did what, when, and why.

## Decision

Write referral_events for workflow, SLA, and notification events, then render timelines from those events.

## Rationale

Event history provides operational transparency and audit support.

## Consequences

Timeline is read-only and append-oriented. Corrections should be new events, not event rewrites.

## Alternatives Considered

Infer timeline from current status; overwrite a JSON timeline field; store only audit logs.

## Related ADRs

ADR-005, ADR-006, ADR-014
