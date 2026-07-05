# E2E Automation Scenarios

These scenarios are ready for implementation with Playwright once browser dependencies and staging credentials are available.

## Positive workflow

1. Register a new user.
2. Verify pending approval state.
3. Login as super admin.
4. Approve user.
5. Assign facility.
6. Login as CHP.
7. Create referral.
8. Submit referral.
9. Login as facility officer or clinician.
10. Receive referral.
11. Assign referral.
12. Start consultation.
13. Record treatment.
14. Record outcome.
15. Complete referral.
16. Close referral.

## Negative workflow

- Unauthorized role cannot access restricted pages.
- Suspended user cannot access app shell.
- Rejected user cannot access app shell.
- Deactivated user cannot access app shell.
- Wrong facility user cannot act on referral.
- Invalid transition fails.
- Duplicate active referral is rejected.
- Missing department fails for department transfer.
