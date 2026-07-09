# Contributing to OCHP

## Architecture Principles

- Backend is the source of truth for workflow rules, permissions, and lifecycle transitions.
- Frontend is a presentation layer for data and metadata returned by secure backend APIs.
- Protected mutations go through secure RPCs.
- Clinical and audit history must be append-only unless a documented correction process exists.
- Backward compatibility is explicit and documented.

## Coding Standards

- Use plain JavaScript modules consistent with the current codebase.
- Keep services centralized; do not scatter Supabase RPC calls through pages when a service exists.
- Sanitize rendered HTML and user-entered text.
- Prefer clear small functions over broad abstractions.
- Keep UI changes compatible with existing pages and print styles.

## Branch Strategy

- Use short-lived feature branches.
- Prefer the `codex/` prefix for Codex-authored branches unless a sprint branch naming policy overrides it.
- Keep sprint-scoped changes isolated.

## Git Tags

Recommended tags:

- `ochp-001-complete`
- `ochp-002a-complete`
- `ochp-002b-complete`
- `ochp-002c-complete`
- `ochp-002c.1-complete`

## Review Process

Every review should check:

- Security and RLS impact.
- Migration safety.
- Workflow lifecycle correctness.
- Backward compatibility.
- Auditability.
- Test/verification evidence.

## Sprint Workflow

1. Confirm sprint scope.
2. Read existing architecture and ADRs.
3. Implement the smallest compatible change.
4. Validate locally.
5. Update relevant docs.
6. Record new ADRs for major decisions.

## Testing Strategy

- Syntax checks for JavaScript modules.
- Inline script checks for static HTML constraints.
- Manual role-based workflow testing.
- Migration dry-runs in non-production Supabase environments.
- Regression checks for dashboards, reports, exports, and auth.

## Definition of Done

A change is done when:

- Scope is complete and no extra sprint work is included.
- Security and workflow invariants are preserved.
- Migrations are forward-only when applicable.
- Documentation is updated.
- Manual verification checklist is satisfied.
- Risks are documented.

## Pull Request Checklist

- [ ] Scope matches sprint/task.
- [ ] No unrelated refactors.
- [ ] Secure RPCs used for protected mutations.
- [ ] RLS and permission impact reviewed.
- [ ] Backward compatibility reviewed.
- [ ] Tests/checks run and documented.
- [ ] Architecture docs/ADRs updated when needed.
