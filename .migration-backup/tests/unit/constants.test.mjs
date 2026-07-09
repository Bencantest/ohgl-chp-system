import test from 'node:test';
import assert from 'node:assert/strict';
import { ROLE_PERMS, DEFAULT_FACS, CATS } from '../../src/constants/appConstants.js';

test('canonical roles include expected production roles', () => {
  for (const role of ['super_admin', 'facility_manager', 'facility_officer', 'clinician', 'chp']) {
    assert.ok(role in ROLE_PERMS, `${role} missing`);
  }
});

test('facility manager and CHP permissions stay separated', () => {
  assert.ok(ROLE_PERMS.facility_manager.includes('settings:manage_facility'));
  assert.ok(!ROLE_PERMS.chp.includes('settings:manage_facility'));
  assert.ok(ROLE_PERMS.chp.includes('referral:create'));
});

test('default facilities and referral categories are available for seed/demo flows', () => {
  assert.ok(DEFAULT_FACS.length >= 1);
  assert.ok(CATS.some(cat => cat.label === 'Maternal Care'));
});
