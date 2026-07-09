import test from 'node:test';
import assert from 'node:assert/strict';
import { canAccessPage, getAllowedPages, getDefaultPage, getRoleLabel, hasPerm, normalizeRole } from '../../src/services/rbac.js';

test('role labels and normalization are stable', () => {
  assert.equal(normalizeRole('facility_manager'), 'facility_manager');
  assert.equal(getRoleLabel('facility_officer'), 'Facility Officer');
});

test('super admin wildcard permission grants all pages and permissions', () => {
  const profile = { role: 'super_admin' };
  assert.equal(hasPerm('anything:anywhere', profile), true);
  assert.equal(canAccessPage('settings', profile), true);
  assert.equal(canAccessPage('audit', profile), true);
});

test('CHP can create own referrals but cannot access tracker or settings', () => {
  const profile = { role: 'chp' };
  assert.equal(hasPerm('referral:create', profile), true);
  assert.equal(canAccessPage('new_referral', profile), true);
  assert.equal(canAccessPage('tracker', profile), false);
  assert.equal(canAccessPage('settings', profile), false);
});

test('clinician can complete referrals and defaults to first allowed referral page', () => {
  const profile = { role: 'clinician' };
  assert.equal(hasPerm('referral:complete', profile), true);
  assert.equal(getDefaultPage(profile), 'new_referral');
  assert.ok(getAllowedPages(profile).includes('tracker'));
});

