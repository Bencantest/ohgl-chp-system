import {
  executeReferralCommand,
  fetchReferralAssignmentHistory,
  fetchReferralClinicalNotes,
  fetchReferralEvents,
  fetchReferralSla,
  getAvailableReferralActions,
} from './dataService.js';
import { refreshDB } from '../main.js';
import { sanitizeText } from '../utils/sanitize.js';

const COMMAND_RPC = {
  submit_referral: 'submit_referral_secure',
  accept_referral: 'accept_referral_secure',
  receive_patient: 'receive_patient_secure',
  assign_referral: 'assign_referral_secure',
  transfer_department: 'transfer_department_secure',
  transfer_facility: 'transfer_facility_secure',
  triage_referral: 'triage_referral_secure',
  start_consultation: 'start_consultation_secure',
  record_investigation: 'record_investigation_secure',
  record_treatment: 'record_treatment_secure',
  record_outcome: 'record_outcome_secure',
  request_followup: 'request_followup_secure',
  schedule_followup: 'schedule_followup_secure',
  complete_referral: 'complete_referral_secure',
  close_referral: 'close_referral_secure',
  cancel_referral: 'cancel_referral_secure',
  reopen_referral: 'reopen_referral_secure',
  archive_referral: 'archive_referral_secure',
};

const REASON_COMMANDS = new Set([
  'assign_referral',
  'transfer_department',
  'transfer_facility',
  'cancel_referral',
  'reopen_referral',
  'archive_referral',
]);

const NOTE_COMMANDS = new Set([
  'accept_referral',
  'receive_patient',
  'triage_referral',
  'start_consultation',
  'record_investigation',
  'record_treatment',
  'record_outcome',
  'request_followup',
  'schedule_followup',
]);

function normalizeActionResponse(data) {
  const body = Array.isArray(data) ? data[0] : data;
  return body || { available_actions: [] };
}

function promptPayload(action) {
  const payload = {};
  if (REASON_COMMANDS.has(action.command)) {
    const reason = prompt(`Reason for ${action.label || action.command}:`);
    if (reason === null) return null;
    payload.reason = sanitizeText(reason, 500);
  }
  if (NOTE_COMMANDS.has(action.command)) {
    const note = prompt(`Clinical note for ${action.label || action.command} (optional):`);
    if (note === null) return null;
    if (note.trim()) payload.note = sanitizeText(note, 2000);
  }
  if (action.command === 'record_outcome' || action.command === 'complete_referral') {
    const outcome = prompt('Outcome (recovered, referred, admitted, follow_up_required, deceased, unknown):', 'unknown');
    if (outcome === null) return null;
    payload.outcome = sanitizeText(outcome, 80);
  }
  if (action.command === 'receive_patient') {
    const receivedBy = prompt('Received by (optional):');
    if (receivedBy === null) return null;
    if (receivedBy.trim()) payload.received_by = sanitizeText(receivedBy, 200);
  }
  if (action.command === 'assign_referral' || action.command === 'transfer_department') {
    const department = prompt('Target department:');
    if (department === null) return null;
    if (department.trim()) payload.department = sanitizeText(department, 200);
  }
  if (action.command === 'transfer_facility') {
    const facilityId = prompt('Target facility ID:');
    if (facilityId === null) return null;
    if (facilityId.trim()) payload.target_facility_id = sanitizeText(facilityId, 80);
  }
  return payload;
}

export const workflowActionService = {
  async loadAvailableActions(referralId) {
    const { data, error } = await getAvailableReferralActions(referralId);
    if (error) throw error;
    return normalizeActionResponse(data);
  },

  async loadReferralArtifacts(referralId) {
    const [events, notes, assignments, sla] = await Promise.all([
      fetchReferralEvents(referralId),
      fetchReferralClinicalNotes(referralId),
      fetchReferralAssignmentHistory(referralId),
      fetchReferralSla(referralId),
    ]);
    const error = events.error || notes.error || assignments.error || sla.error;
    if (error) throw error;
    return {
      timeline: events.data || [],
      clinicalNotes: notes.data || [],
      assignmentHistory: assignments.data || [],
      sla: sla.data || [],
    };
  },

  async executeAction(referralId, action) {
    const commandRpc = COMMAND_RPC[action.command];
    if (!commandRpc) throw new Error(`Unsupported workflow command: ${action.command}`);
    const payload = promptPayload(action);
    if (payload === null) return { cancelled: true };
    if (!confirm(`Execute ${action.label || action.command}?`)) return { cancelled: true };
    const { error } = await executeReferralCommand(commandRpc, referralId, payload);
    if (error) throw error;
    await refreshDB();
    return { success: true };
  },
};
