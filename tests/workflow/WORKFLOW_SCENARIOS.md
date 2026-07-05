# Workflow Test Scenarios

## Positive End-to-End Scenario

1. Register user.
2. Confirm user enters pending approval.
3. Super admin approves user.
4. Assign user to facility.
5. Create referral.
6. Submit referral.
7. Accept/receive referral.
8. Assign referral.
9. Start consultation.
10. Record treatment.
11. Record outcome.
12. Complete referral.
13. Close referral.

Expected results:

- Each command returns the expected canonical status and stage.
- Referral events are written.
- Assignment history is written for assignment changes.
- Clinical notes are versioned.
- SLA timers update.
- Audit logs are written.

## Negative Scenarios

- Unauthorized role cannot execute restricted command.
- Invalid workflow transition fails.
- Wrong facility cannot act on referral.
- Missing department fails for department transfer.
- Duplicate active referral is rejected.
- Suspended user cannot access app.
- Rejected user cannot access app.
- Deactivated user cannot access app.
