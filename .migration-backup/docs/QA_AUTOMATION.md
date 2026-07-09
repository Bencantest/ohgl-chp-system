# QA Automation Framework

OCHP-003C establishes automated and executable-ready quality gates for implemented functionality. The suite is intentionally dependency-free for the current static frontend architecture and can run in CI without a live Supabase project.

## Test Inventory

| Area | Test File | Coverage |
| --- | --- | --- |
| Unit | `tests/unit/sanitize.test.mjs` | HTML escaping and text sanitization |
| Unit | `tests/unit/rbac.test.mjs` | Role labels, permissions, page access |
| Unit | `tests/unit/constants.test.mjs` | Canonical roles, permissions, seed constants |
| Integration | `tests/integration/rpc-contracts.test.mjs` | IAM, referral, and workflow metadata RPC contracts |
| Workflow | `tests/workflow/workflow-engine.test.mjs` | Workflow commands, metadata, transitions, side effects |
| Security | `tests/security/security-controls.test.mjs` | Unauthorized role, wrong facility, invalid transition, missing permissions, direct access controls |
| Regression | `tests/regression/regression-static.test.mjs` | Secure view usage, tracker workflow UI regression, dashboard/report status paths |
| Performance | `tests/performance/performance-baselines.test.mjs` | Dashboard/search-style baseline checks |
| E2E | `tests/e2e/E2E_SCENARIOS.md` | Browser scenarios for full positive and negative workflows |

## Coverage Summary

Covered by runnable tests:

- Identity RPC exposure.
- Registration and approval RPC contracts.
- Role assignment and facility assignment RPC contracts.
- Permission enforcement in frontend RBAC and backend migration contracts.
- Referral creation RPC contract.
- Workflow command presence and grants.
- Timeline, assignment history, clinical notes, SLA, audit, and notification side-effect contracts.
- Workflow metadata RPC contracts.
- RLS and direct user table write protections.
- Unauthorized role, wrong facility, invalid transition, missing permission, missing department, duplicate referral, missing outcome, and replay/archived referral protections via static SQL contract checks.
- Dashboard/search baseline performance on synthetic data.

Covered as executable-ready scenarios pending browser/live environment:

- Full registration to close referral E2E journey.
- Suspended, rejected, and deactivated user browser access checks.
- Live direct table access attempts through Supabase client.
- Live notification delivery checks.

## Running Tests

```bash
npm test
```

Full local quality sweep:

```bash
npm run check:syntax
npm run check:js
npm run validate:docs
npm run validate:migrations
npm test
```

## Remaining Gaps

- Live Supabase integration tests require staging credentials and synthetic fixtures.
- Browser E2E automation should be implemented with Playwright after dependency approval.
- Performance tests are synthetic baselines; production-like datasets should be tested in staging.
- Notification delivery provider tests are pending provider selection.
- RLS tests currently validate migration controls statically; live cross-user RLS tests remain a priority.
