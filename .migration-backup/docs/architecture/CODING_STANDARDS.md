# Coding Standards

## JavaScript Standards

- Use ES modules.
- Keep protected Supabase calls in service modules.
- Avoid hardcoded workflow business rules in UI code.
- Sanitize untrusted text before rendering.
- Prefer clear functions and existing local patterns.

## SQL Standards

- Use snake_case identifiers.
- Use explicit permissions and grants.
- Keep secure RPCs responsible for validation and side effects.
- Preserve audit and clinical history.

## Naming Conventions

- Secure RPCs: `{verb}_{entity}_secure`.
- Workflow commands: `{action}_referral_secure` where applicable.
- Migration files: `YYYYMMDD_XXXXXX_description.sql`.
- Documentation files: uppercase descriptive names for major references.

## Migration Conventions

- Forward-only by default.
- Additive changes preferred.
- Include compatibility strategy for canonical field migrations.
- Do not remove legacy fields without documented deprecation.

## RPC Conventions

- Validate auth first.
- Validate permission.
- Validate ownership/facility scope.
- Validate payload and lifecycle state.
- Write audit/timeline side effects consistently.

## Component Conventions

- Reuse existing styles and components.
- Keep forms accessible and label-driven.
- Workflow components consume backend metadata.
- Avoid nested UI cards where a simple panel is sufficient.

## Documentation Conventions

- Markdown with clear headings.
- Mermaid diagrams for architecture and sequence flows.
- ADRs for significant decisions.
- Update docs in the same sprint as behavior changes.

## Commit Message Conventions

Use concise imperative messages:

- `docs: add production readiness report`
- `ci: add migration validation workflow`
- `test: scaffold workflow scenarios`

## Branch Strategy

- Use short-lived feature branches.
- Prefer `codex/` prefix for Codex work.
- Protect production deployment branches.

## Definition of Done

- Scope complete.
- CI passes.
- Security impact reviewed.
- Documentation updated.
- Manual verification checklist completed.
- Risks documented.
