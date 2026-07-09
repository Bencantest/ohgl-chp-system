import { sb } from './supabaseClient.js';

/**
 * Fetches core application data with fallback error handling.
 */
export function fetchCoreData() {
  return Promise.all([
    sb.from('facilities').select('*').order('location'),
    sb.from('chp_directory_secure').select('*').order('code'),
    sb.from('referrals_secure').select('*').order('created_at', { ascending: true }),
    sb.from('coverage_areas').select('*').order('sub_location'),
  ]);
}

export function fetchUserProfile(userId) {
  return sb.from('users').select('*').eq('id', userId).maybeSingle();
}

export function fetchUsers() {
  return sb.from('users').select('id,facility_id,role,full_name,email,phone,active,last_login_at,created_at').order('full_name');
}

export function listPendingUsersSecure() {
  return sb.rpc('list_pending_users_secure');
}

export function listUsersSecure() {
  return sb.rpc('list_users_secure');
}

export function approveUserSecure(targetUserId, facilityId, reason = '') {
  return sb.rpc('approve_user_secure', { target_user_id: targetUserId, facility_id: facilityId, reason });
}

export function rejectUserSecure(targetUserId, reason) {
  return sb.rpc('reject_user_secure', { target_user_id: targetUserId, reason });
}

export function suspendUserSecure(targetUserId, reason) {
  return sb.rpc('suspend_user_secure', { target_user_id: targetUserId, reason });
}

export function reactivateUserSecure(targetUserId, reason) {
  return sb.rpc('reactivate_user_secure', { target_user_id: targetUserId, reason });
}

export function deactivateUserSecure(targetUserId, reason) {
  return sb.rpc('deactivate_user_secure', { target_user_id: targetUserId, reason });
}

export function assignUserFacilitySecure(targetUserId, facilityId, reason) {
  return sb.rpc('assign_user_facility_secure', { target_user_id: targetUserId, facility_id: facilityId, reason });
}

export function changeUserRoleSecure(targetUserId, newRole, reason) {
  return sb.rpc('change_user_role_secure', { target_user_id: targetUserId, new_role: newRole, reason });
}

export function fetchUserAccessAudit(limit = 50) {
  return sb.from('user_access_audit')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
}

export function writeAuditLog({ actorId, action, tableName, recordId, facilityId, changes }) {
  return sb.from('audit_logs').insert({
    actor_id: actorId,
    action,
    table_name: tableName,
    record_id: recordId ? String(recordId) : null,
    facility_id: facilityId,
    changes,
  });
}

export function createReferralRecord(payload) {
  return sb.rpc('create_referral_secure', { payload });
}

// ──── Facility CRUD ────────────────────────────────────────────────────────────

export function updateFacilityRecord(id, payload) {
  return sb.from('facilities').update(payload).eq('id', id);
}

export function deleteFacilityRecord(id) {
  return sb.from('facilities').delete().eq('id', id);
}

export function createFacilityRecord(payload) {
  return sb.from('facilities').insert(payload).select().single();
}

// ──── Referral CRUD ───────────────────────────────────────────────────────────

/**
 * Update a referral record via the secure RPC.
 * Falls back to a direct update if the RPC is unavailable (non-production).
 */
export async function updateReferralSecureFull(referralId, payload) {
  // Try the secure RPC first
  const rpcResult = await sb.rpc('update_referral_secure_full', {
    referral_id: referralId,
    updates: payload,
  });
  // Some deployments use a different RPC signature — try direct update if RPC not found
  if (rpcResult.error?.code === 'PGRST202' || rpcResult.error?.message?.includes('Could not find')) {
    return sb.from('referrals').update(payload).eq('id', referralId);
  }
  return rpcResult;
}

export async function deleteReferralRecord(referralId) {
  const rpcResult = await sb.rpc('delete_referral_secure', { referral_id: referralId });
  if (rpcResult.error?.code === 'PGRST202' || rpcResult.error?.message?.includes('Could not find')) {
    return sb.from('referrals').delete().eq('id', referralId);
  }
  return rpcResult;
}

// ──── CHP Directory ───────────────────────────────────────────────────────────

export function createCHPRecord(payload) {
  return sb.from('chp_directory').insert(payload).select().single();
}

export function updateCHPRecord(id, payload) {
  return sb.from('chp_directory').update(payload).eq('id', id);
}

export function deleteCHPRecord(id) {
  return sb.from('chp_directory').delete().eq('id', id);
}

// ──── Workflow Actions ─────────────────────────────────────────────────────────

export function getWorkflowActionDefinition(commandName) {
  return sb.rpc('get_workflow_action_definition', { command_name: commandName });
}

export function getWorkflowReferenceData(commandName) {
  return sb.rpc('get_workflow_reference_data', { command_name: commandName });
}

export function getAvailableReferralActions(referralId) {
  return sb.rpc('get_available_referral_actions', { referral_id: referralId });
}

export function executeReferralCommand(commandRpc, referralId, payload = {}) {
  return sb.rpc(commandRpc, { p_referral_id: referralId, payload });
}

export function fetchReferralEvents(referralId) {
  return sb.from('referral_events')
    .select('created_at,event_name,actor_role,department,reason,metadata,event_category,actor:users!referral_events_actor_id_fkey(full_name),facility:facilities!referral_events_facility_id_fkey(name)')
    .eq('referral_id', referralId)
    .order('created_at', { ascending: false });
}

export function fetchReferralClinicalNotes(referralId) {
  return sb.from('referral_clinical_notes')
    .select('id,note_type,note_text,author_role,version,created_at,author:users!referral_clinical_notes_author_id_fkey(full_name)')
    .eq('referral_id', referralId)
    .order('note_type', { ascending: true })
    .order('version', { ascending: false });
}

export function fetchReferralAssignmentHistory(referralId) {
  return sb.from('referral_assignment_history')
    .select('created_at,previous_owner_type,new_owner_type,previous_department,new_department,reason,assignment_type,actor:users!referral_assignment_history_actor_id_fkey(full_name)')
    .eq('referral_id', referralId)
    .order('created_at', { ascending: false });
}

export function fetchReferralSla(referralId) {
  return sb.from('referral_sla_timers')
    .select('transition_name,target_at,warning_at,breach_at,completed_at,breached,created_at,updated_at')
    .eq('referral_id', referralId)
    .order('target_at', { ascending: true });
}

// ──── CHP Secure Upsert ───────────────────────────────────────────────────────

export function saveChpRecord(payload) {
  return sb.rpc('upsert_chp_secure', { payload });
}

export function saveCoverageAreaRecord(payload) {
  return sb.rpc('upsert_coverage_area_secure', { payload });
}

export function deleteChpRecord(chpId) {
  return sb.from('chp_directory').delete().eq('id', chpId);
}

// ──── Audit Events ────────────────────────────────────────────────────────────

export function fetchAuditEvents(limit = 100) {
  return sb.from('audit_logs')
    .select('created_at,action,table_name,record_id,actor_id,ip_address,changes,users(email,full_name)')
    .order('created_at', { ascending: false })
    .limit(limit);
}

// ──── Notifications ───────────────────────────────────────────────────────────

export function fetchNotifications(userId, facilityId) {
  if (!userId) return Promise.resolve({ data: [], error: null });
  let query = sb.from('notifications')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(50);
  if (facilityId) {
    query = query.or(`user_id.eq.${userId},and(facility_id.eq.${facilityId},user_id.is.null)`);
  } else {
    query = query.eq('user_id', userId);
  }
  return query;
}

export function markNotificationRead(notifId) {
  return sb.from('notifications').update({ read: true }).eq('id', notifId);
}

export function markAllNotificationsRead(userId, facilityId) {
  if (!userId) return Promise.resolve({ data: [], error: null });
  let query = sb.from('notifications').update({ read: true }).eq('read', false);
  if (facilityId) {
    query = query.or(`user_id.eq.${userId},and(facility_id.eq.${facilityId},user_id.is.null)`);
  } else {
    query = query.eq('user_id', userId);
  }
  return query;
}

// ──── Invite Staff ─────────────────────────────────────────────────────────────

/**
 * Invite a staff member (clinician / receptionist / monitor) via the backend API.
 * Requires the caller to be super_admin — enforced server-side.
 */
export async function inviteStaffUser(email, fullName, role, facilityId) {
  const { data: { session } } = await sb.auth.getSession();
  const token = session?.access_token;
  if (!token) throw new Error('Not authenticated');

  // The api-server is proxied at /api-server in Vite dev; adjust if deployed
  const apiBase = import.meta.env.VITE_API_BASE_URL || '';
  const resp = await fetch(`${apiBase}/api/admin/invite-staff`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ email, full_name: fullName, role, facility_id: facilityId }),
  });

  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) throw new Error(data.error || `Server error ${resp.status}`);
  return data;
}
