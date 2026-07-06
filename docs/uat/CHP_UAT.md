# CHP UAT

| Test ID | Description | Steps | Expected Result | Actual Result | Pass/Fail | Comments |
| --- | --- | --- | --- | --- | --- | --- |
| CHP-UAT-001 | Register as CHP | Open app, select Register, enter name, phone, email, password, optional CHP code, submit. | Registration succeeds and account is pending approval. | Pending manual UAT. | TBD | Verify no elevated role can be self-selected. |
| CHP-UAT-002 | Pending user blocked | Login before approval. | User sees awaiting approval screen and cannot access modules. | Pending manual UAT. | TBD | Requires test pending account. |
| CHP-UAT-003 | Approved CHP login | Super Admin approves CHP, then CHP logs in. | CHP lands on permitted referral page. | Pending manual UAT. | TBD | Confirm no tracker/settings/audit access. |
| CHP-UAT-004 | Submit referral | Complete New Referral form and submit. | Referral created through secure RPC and appears in My Referrals. | Pending manual UAT. | TBD | Use synthetic patient data only. |
| CHP-UAT-005 | Search own referrals | Use My Referrals search/filter. | Results filter correctly without errors. | Static regression tests pass for search paths. | Pass | Manual browser check still required. |
| CHP-UAT-006 | Notifications | Trigger a referral status update. | CHP sees relevant notification if notification exists. | Pending manual UAT. | TBD | Depends on configured notification records. |
