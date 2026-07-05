# ADR-009 Clinical Notes Versioning

## Status

Accepted

## Context

Clinical notes are care records and should not be silently overwritten.

## Decision

Store clinical notes as versioned records by note type with author, role, version, previous note reference, metadata, and timestamp.

## Rationale

Versioning preserves clinical accountability and supports review of historical versions.

## Consequences

UI must display versions and avoid destructive note edits.

## Alternatives Considered

Single notes field on referral; audit-only note changes; external document storage only.

## Related ADRs

ADR-005, ADR-008, ADR-014
