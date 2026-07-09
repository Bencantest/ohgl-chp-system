# Facility Manager UAT

| Test ID | Description | Steps | Expected Result | Actual Result | Pass/Fail | Comments |
| --- | --- | --- | --- | --- | --- | --- |
| FM-UAT-001 | Login as Facility Manager | Login with approved facility manager account. | Dashboard opens with facility-scoped data. | Pending manual UAT. | TBD | Validate assigned facility only. |
| FM-UAT-002 | Receive referral | Open Tracker after CHP submits referral. | Referral appears for the manager facility. | Pending manual UAT. | TBD | Cross-facility isolation required. |
| FM-UAT-003 | Assign referral | Use available workflow action to assign department/user. | Assignment event is recorded and workflow updates. | Workflow RPC tests pass. | Pass | Manual browser action required. |
| FM-UAT-004 | Clinical notes visibility | Open referral workflow details. | Notes/history display according to permissions. | Pending manual UAT. | TBD | Use synthetic data. |
| FM-UAT-005 | Complete referral path | Progress referral to completion with authorized workflow action. | Status updates and audit/workflow events persist. | Workflow side-effect tests pass. | Pass | Manual browser verification required. |
| FM-UAT-006 | Reports | Open monthly report, apply filters, export. | Report loads and export actions generate files/data. | Pending manual UAT. | TBD | Browser export required. |
