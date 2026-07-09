# Clinician UAT

| Test ID | Description | Steps | Expected Result | Actual Result | Pass/Fail | Comments |
| --- | --- | --- | --- | --- | --- | --- |
| CLIN-UAT-001 | Login as Clinician | Login with approved clinician account. | Permitted referral pages load. | Pending manual UAT. | TBD | Confirm no IAM/settings access. |
| CLIN-UAT-002 | View assigned referrals | Open referral tracker/worklist. | Facility-scoped referrals are visible. | Pending manual UAT. | TBD | Cross-facility isolation required. |
| CLIN-UAT-003 | Add clinical note | Use workflow note/action if available. | Clinical note/event persists through secure workflow path. | Workflow side-effect tests pass. | Pass | Manual browser check required. |
| CLIN-UAT-004 | Complete referral | Execute complete action with outcome. | Referral reaches completed state. | Workflow validation tests pass. | Pass | Validate required outcome. |
| CLIN-UAT-005 | Permission boundary | Attempt admin/IAM pages. | Access denied or navigation hidden. | RBAC unit tests pass. | Pass | Manual role smoke check required. |
