# Changelog Guidelines

OCHP changelogs must be clear to technical and non-technical stakeholders.

## Format

Use release headings:

```markdown
## v1.0.0 - YYYY-MM-DD

### Added
### Changed
### Fixed
### Security
### Deprecated
### Removed
### Migration Notes
### Known Issues
```

## Categories

Added: new functionality.

Changed: behavior or process changes that are not fixes.

Fixed: bug fixes.

Security: security improvements or vulnerabilities fixed.

Deprecated: features or fields that remain available but will be removed later.

Removed: removed features or compatibility layers.

Migration Notes: database, deployment, or operational steps.

Known Issues: approved issues that remain after release.

## Audience

Every release note should be understandable by:

- Developers.
- Testers.
- Project managers.
- Healthcare administrators.
- County government stakeholders.
- NGOs and donors.

## Rules

- Do not expose secrets, PHI, or private incident details.
- Mention user-facing impact plainly.
- Link to ADRs for architecture changes.
- Include rollback or migration notes where relevant.
- Note whether the release is MAJOR, MINOR, PATCH, or RC.

## Example

```markdown
## v1.0.0-rc1 - 2026-07-05

### Added
- Release candidate for OCHP pilot readiness.
- Metadata-driven workflow action dialogs.

### Security
- Confirmed secure RPC command ownership for referral lifecycle.

### Migration Notes
- Apply migrations through `20260705_000016_workflow_metadata_engine.sql`.

### Known Issues
- Full browser E2E automation remains pending.
```
