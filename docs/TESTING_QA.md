# Quality Assurance

## Manual Testing Checklist

- [ ] Login and logout.
- [ ] Register new user.
- [ ] Approve, reject, suspend, reactivate, deactivate user.
- [ ] Create referral.
- [ ] Render tracker.
- [ ] Execute available workflow actions.
- [ ] View timeline, notes, assignment history, and SLA.
- [ ] Load dashboards and reports.

## Regression Testing Checklist

- [ ] Existing dashboards still load.
- [ ] Existing reports still load.
- [ ] Existing exports still work.
- [ ] Referral search and filters still work.
- [ ] Legacy fields remain visible where required.
- [ ] Authentication session restore works.

## Smoke Testing Checklist

- [ ] Static app loads over HTTPS.
- [ ] Supabase config present.
- [ ] Auth screen appears.
- [ ] Approved user reaches default page.
- [ ] Core data refresh succeeds.
- [ ] No console-blocking JavaScript errors.

## Security Testing Checklist

- [ ] CHP cannot access unrelated facility data.
- [ ] Suspended/rejected/deactivated users are blocked.
- [ ] Facility user cannot execute super admin IAM actions.
- [ ] Invalid workflow command fails server-side.
- [ ] Direct protected table write is rejected.
- [ ] Audit log records protected actions.

## Performance Testing Checklist

- [ ] Dashboard loads with expected facility dataset.
- [ ] Tracker pagination remains responsive.
- [ ] Notification query is bounded.
- [ ] Secure views use indexes for common filters.
- [ ] Workflow metadata calls do not fetch unnecessary reference data.

## Accessibility Checklist

- [ ] Forms have labels.
- [ ] Buttons have clear text or title.
- [ ] Modal/dialog focus is usable.
- [ ] Keyboard navigation works for core workflows.
- [ ] Color is not the only indicator of status.

## User Acceptance Testing

UAT should include CHP, facility officer, facility manager, and super admin representatives. Each group should validate the workflows they own using synthetic but realistic data.
