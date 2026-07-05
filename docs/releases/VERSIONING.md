# Versioning Strategy

OCHP uses Semantic Versioning: `MAJOR.MINOR.PATCH`.

```text
MAJOR.MINOR.PATCH
```

Examples: `v1.0.0`, `v1.0.1`, `v1.1.0`, `v2.0.0`.

## MAJOR Versions

Increment the MAJOR version for changes that significantly alter platform architecture, deployment model, compatibility expectations, or healthcare module boundaries.

Examples:

- Breaking architecture changes.
- Major healthcare module families that reshape the platform.
- Platform redesigns.
- Multi-facility/county tenancy changes that require planned migration.
- Breaking API or database compatibility changes.

## MINOR Versions

Increment the MINOR version for backward-compatible product capability expansion.

Examples:

- New healthcare features.
- New modules such as Clinical Operations, Laboratory, Radiology, or Pharmacy.
- Workflow enhancements that preserve existing contracts.
- New reports, dashboards, or integrations.
- New metadata-driven UI capabilities.

## PATCH Versions

Increment the PATCH version for backward-compatible corrections and maintenance.

Examples:

- Bug fixes.
- Security fixes.
- Performance improvements.
- Documentation corrections.
- Non-breaking operational improvements.
- CI/CD and testing improvements.

## Pre-Releases

Release candidates use the format:

```text
vMAJOR.MINOR.PATCH-rcN
```

Examples:

- `v1.0.0-rc1`
- `v1.0.0-rc2`
- `v2.0.0-rc1`

## Build Metadata

Build metadata may be added for internal deployment tracking when needed:

```text
v1.0.0+20260705.shaabcdef
```

Build metadata must not change release semantics.

## Version Authority

The release owner proposes the version. Architecture, QA, and product stakeholders confirm whether the release is MAJOR, MINOR, PATCH, or RC.
