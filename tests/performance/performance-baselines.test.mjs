import test from 'node:test';
import assert from 'node:assert/strict';

function makeReferral(i) {
  return {
    id: `REF-${i}`,
    patient: `Patient ${i}`,
    national_id: `${10000000 + i}`,
    workflow_status: i % 5 === 0 ? 'Completed' : 'Submitted',
    referral_facility: i % 2 === 0 ? 'Oasis Doctors Siaya' : 'Oasis Medical Centre',
    date: '2026-07-05',
  };
}

function searchRows(rows, query) {
  const q = query.toLowerCase();
  return rows.filter(r => [r.id, r.patient, r.national_id, r.workflow_status, r.referral_facility].join(' ').toLowerCase().includes(q));
}

test('tracker/search-style filtering stays under baseline for 5000 referrals', () => {
  const rows = Array.from({ length: 5000 }, (_, i) => makeReferral(i));
  const start = performance.now();
  const result = searchRows(rows, 'siaya');
  const elapsed = performance.now() - start;
  assert.ok(result.length > 0);
  assert.ok(elapsed < 75, `search took ${elapsed}ms`);
});

test('dashboard-style aggregation stays under baseline for 5000 referrals', () => {
  const rows = Array.from({ length: 5000 }, (_, i) => makeReferral(i));
  const start = performance.now();
  const completed = rows.filter(r => r.workflow_status === 'Completed').length;
  const active = rows.filter(r => r.workflow_status !== 'Completed').length;
  const elapsed = performance.now() - start;
  assert.equal(completed + active, rows.length);
  assert.ok(elapsed < 75, `aggregation took ${elapsed}ms`);
});
