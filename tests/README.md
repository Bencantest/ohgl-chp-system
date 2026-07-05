# Testing Framework

OCHP tests are organized by risk and scope.

## Structure

- `tests/unit/`: utility, RBAC, constants, and pure module tests.
- `tests/integration/`: static and future live Supabase contract tests.
- `tests/workflow/`: referral workflow command, metadata, transition, and side-effect tests.
- `tests/security/`: authorization, RLS, replay, invalid transition, and direct access controls.
- `tests/regression/`: tests that guard existing dashboard, report, tracker, and secure-view behavior.
- `tests/performance/`: synthetic baseline checks for dashboard, tracker, search, timeline, and referral operations.
- `tests/e2e/`: browser-level journeys and executable-ready scenarios.

## Running Tests

```bash
npm test
```

Current runnable tests are dependency-free and do not require live Supabase credentials.

## Priority Workflows to Automate in Browser E2E

1. Registration to pending approval.
2. Super admin approval and facility assignment.
3. CHP referral creation and submission.
4. Facility receiving and assignment.
5. Consultation, treatment, outcome, completion, and closure.
6. Negative role/facility/transition tests.

## Test Data Principles

- Use synthetic patient data only.
- Reset staging data between full workflow runs.
- Never use production PHI in automated tests.
