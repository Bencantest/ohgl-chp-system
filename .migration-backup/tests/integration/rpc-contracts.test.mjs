import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const dataService = readFileSync('src/services/dataService.js', 'utf8');
const workflowService = readFileSync('src/services/workflowActionService.js', 'utf8');

test('identity and registration secure RPCs are exposed through data service', () => {
  for (const rpc of [
    'list_pending_users_secure',
    'list_users_secure',
    'approve_user_secure',
    'reject_user_secure',
    'suspend_user_secure',
    'reactivate_user_secure',
    'deactivate_user_secure',
    'assign_user_facility_secure',
    'change_user_role_secure',
  ]) {
    assert.match(dataService, new RegExp(`sb\\.rpc\\('${rpc}'`), `${rpc} missing`);
  }
});

test('referral creation and workflow metadata RPC contracts are centralized', () => {
  for (const rpc of [
    'create_referral_secure',
    'get_workflow_action_definition',
    'get_workflow_reference_data',
    'get_available_referral_actions',
  ]) {
    assert.match(dataService, new RegExp(`sb\\.rpc\\('${rpc}'`), `${rpc} missing`);
  }
});

test('workflow action service uses backend rpc_name metadata instead of a hardcoded command map', () => {
  assert.match(workflowService, /definition\.rpc_name/);
  assert.doesNotMatch(workflowService, /const COMMAND_RPC/);
  assert.doesNotMatch(workflowService, /prompt\(/);
  assert.doesNotMatch(workflowService, /confirm\(/);
});
