import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const main = readFileSync('src/main.js', 'utf8');
const tracker = readFileSync('src/pages/tracker.js', 'utf8');
const dashboard = readFileSync('src/pages/dashboard.js', 'utf8');
const reports = readFileSync('src/pages/report.js', 'utf8');

test('core data refresh still reads secure views', () => {
  assert.match(main, /fetchCoreData/);
  assert.match(readFileSync('src/services/dataService.js', 'utf8'), /referrals_secure/);
  assert.match(readFileSync('src/services/dataService.js', 'utf8'), /chp_directory_secure/);
});

test('tracker workflow status is rendered read-only and actions use workflow service', () => {
  assert.match(tracker, /workflowActionService\.loadAvailableActions/);
  assert.match(tracker, /executeReferralWorkflowAction/);
  assert.doesNotMatch(tracker, /<select class="ss"[^>]+workflow_status/);
});

test('dashboard and reports retain referral status aggregation paths', () => {
  assert.match(dashboard, /workflow_status \|\| r\.status/);
  assert.match(reports, /workflow_status \|\| r\.status/);
});
