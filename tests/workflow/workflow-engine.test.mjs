import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const engine = readFileSync('supabase/migrations/20260705_000015_referral_workflow_command_engine.sql', 'utf8');
const metadata = readFileSync('supabase/migrations/20260705_000016_workflow_metadata_engine.sql', 'utf8');

const commands = [
  'submit_referral',
  'accept_referral',
  'receive_patient',
  'assign_referral',
  'transfer_department',
  'transfer_facility',
  'triage_referral',
  'start_consultation',
  'record_investigation',
  'record_treatment',
  'record_outcome',
  'request_followup',
  'schedule_followup',
  'complete_referral',
  'close_referral',
  'cancel_referral',
  'reopen_referral',
  'archive_referral',
];

test('all workflow command RPCs are implemented and granted', () => {
  for (const command of commands) {
    assert.match(engine, new RegExp(`CREATE OR REPLACE FUNCTION ${command}_secure`), `${command}_secure function missing`);
    assert.match(engine, new RegExp(`GRANT EXECUTE ON FUNCTION ${command}_secure`), `${command}_secure grant missing`);
  }
});

test('metadata definitions exist for available workflow commands', () => {
  for (const command of commands.filter(c => !['request_followup', 'schedule_followup'].includes(c))) {
    assert.match(metadata, new RegExp(`WHEN '${command}'`), `${command} metadata missing`);
  }
});

test('invalid transitions and archived referral replay protection are enforced in SQL', () => {
  assert.match(engine, /Invalid referral transition from % to %/);
  assert.match(engine, /Archived referrals cannot be modified/);
  assert.match(engine, /Closed referrals must be reopened before modification/);
  assert.match(engine, /Cancelled referrals must be reopened before modification/);
});

test('workflow side effects include timeline, notes, assignment history, audit, SLA, and notifications', () => {
  for (const fn of ['write_referral_event', 'write_referral_note', 'write_assignment_history', 'write_referral_audit', 'update_referral_sla', 'queue_notification_event']) {
    assert.match(engine, new RegExp(fn), `${fn} missing`);
  }
});
