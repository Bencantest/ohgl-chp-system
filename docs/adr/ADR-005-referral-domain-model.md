# ADR-005 Referral Domain Model

## Status

Accepted

## Context

Referrals moved beyond a simple status field into clinical, ownership, event, and SLA state.

## Decision

Model referrals as a domain aggregate with canonical status, stage, outcome, owner, events, notes, assignment history, and SLA timers.

## Rationale

Healthcare workflows need traceability, ownership, and extensibility for future clinical modules.

## Consequences

Legacy fields remain for compatibility but canonical fields are authoritative.

## Alternatives Considered

Single referral table only; free-text status tracking; separate referral tables per facility.

## Related ADRs

ADR-006, ADR-008, ADR-009, ADR-010, ADR-011
