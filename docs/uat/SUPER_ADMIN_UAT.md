# Super Admin UAT

| Test ID | Description | Steps | Expected Result | Actual Result | Pass/Fail | Comments |
| --- | --- | --- | --- | --- | --- | --- |
| SA-UAT-001 | Login as Super Admin | Login with Super Admin account. | Dashboard and admin navigation are available. | Pending manual UAT. | TBD | Requires seeded/approved Super Admin. |
| SA-UAT-002 | Register facility | Open Settings, add facility. | Facility is created and selectable. | Pending manual UAT. | TBD | Use test facility in non-production. |
| SA-UAT-003 | Approve user | Open IAM Admin, approve pending CHP, assign facility. | User becomes approved and active with CHP role. | Secure IAM RPC tests pass. | Pass | Manual browser request verification required. |
| SA-UAT-004 | Assign elevated role | Change approved user role. | Role changes only through Super Admin RPC. | Secure IAM RPC tests pass. | Pass | Verify no self-role change. |
| SA-UAT-005 | Deactivate/reactivate user | Use IAM lifecycle actions with reason. | Status changes and audit records persist. | Secure IAM RPC tests pass. | Pass | Manual audit review required. |
| SA-UAT-006 | Audit review | Open Audit page. | Recent auth, IAM, referral, and data changes are visible. | Pending manual UAT. | TBD | Requires generated events. |
| SA-UAT-007 | Coverage area update | Open CHP Directory and change coverage status. | `coverage_areas` updates without changing CHP active state. | Static validation confirms separate coverage RPC. | Pass | Manual database spot-check required. |
