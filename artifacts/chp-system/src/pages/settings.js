import { fac, DB, setDB } from '../services/state.js';
import { ensurePageAccess, hasPerm } from '../services/rbac.js';
import { updateFacilityRecord, deleteFacilityRecord, createFacilityRecord, listUsersSecure, approveUserSecure, rejectUserSecure, suspendUserSecure, reactivateUserSecure, deactivateUserSecure, assignUserFacilitySecure, changeUserRoleSecure, fetchUserAccessAudit, inviteStaffUser } from '../services/dataService.js';
import { audit } from '../services/authService.js';
import { h, sanitizeText } from '../utils/sanitize.js';
import { makeFac } from '../services/mappers.js';
import { openModal, closeModal } from '../components/modal.js';
import { updateHeader, showPage, refreshDB } from '../main.js';
import { renderDash } from './dashboard.js';

export function loadSettings() {
  if (!ensurePageAccess('settings', 'settings-alert')) return;
  const f = fac();
  document.getElementById('settings-fac').textContent = f ? f.location + ' - ' + f.name : 'No facility selected';
  if (!f) return;
  document.getElementById('s-name').value = f.name || '';
  document.getElementById('s-location').value = f.location || '';
  document.getElementById('s-subcounty').value = f.subcounty || '';
  document.getElementById('s-level').value = f.level || 'Level 4';
  document.getElementById('s-email').value = f.email || '';
  document.getElementById('s-phone').value = f.phone || '';
  document.getElementById('s-token').value = f.token || 200;
  document.getElementById('s-year').value = f.year || 2026;
  document.getElementById('s-compiler').value = f.compiler || '';
  document.getElementById('s-coic').value = f.coic || '';
  const userBtn = document.getElementById('user-admin-btn');
  if (userBtn) userBtn.style.display = hasPerm('*') ? 'inline-flex' : 'none';
}

export async function saveSettings() {
  if (!ensurePageAccess('settings', 'settings-alert')) return;
  const f = fac();
  if (!f) { alert('No facility selected.'); return; }
  f.name = document.getElementById('s-name').value;
  f.location = document.getElementById('s-location').value;
  f.subcounty = document.getElementById('s-subcounty').value;
  f.level = document.getElementById('s-level').value;
  f.email = document.getElementById('s-email').value;
  f.phone = document.getElementById('s-phone').value;
  f.token = parseFloat(document.getElementById('s-token').value) || 200;
  f.year = parseInt(document.getElementById('s-year').value) || 2026;
  f.compiler = document.getElementById('s-compiler').value;
  f.coic = document.getElementById('s-coic').value;

  const payload = {
    name: sanitizeText(f.name, 160),
    location: sanitizeText(f.location, 120),
    subcounty: sanitizeText(f.subcounty, 120),
    level: f.level,
    email: sanitizeText(f.email, 160),
    phone: sanitizeText(f.phone, 40),
    token_rate: f.token,
    financial_year: f.year,
    compiler: sanitizeText(f.compiler, 160),
    coic: sanitizeText(f.coic, 160),
  };
  const { error } = await updateFacilityRecord(f.id, payload);
  if (error) { alert(error.message); return; }
  await audit('update', 'facilities', f.id, { fields: Object.keys(payload) });
  updateHeader();
  document.getElementById('settings-alert').innerHTML = `<div class="alert alert-s"><i class="ti ti-circle-check"></i> Settings saved for ${f.location} - ${f.name}</div>`;
  setTimeout(() => (document.getElementById('settings-alert').innerHTML = ''), 3000);
}

export async function deleteFacility() {
  if (!ensurePageAccess('settings', 'settings-alert')) return;
  const f = fac();
  if (!f) return;
  if (!confirm('Delete ' + f.location + ' - ' + f.name + ' and ALL its data?')) return;
  const { error } = await deleteFacilityRecord(f.id);
  if (error) { alert(error.message); return; }
  await audit('delete', 'facilities', f.id, { name: f.name });
  const newFacs = DB.facilities.filter(x => x.id !== f.id);
  const activeFacId = newFacs.length ? newFacs[0].id : null;
  setDB({ facilities: newFacs, activeFacId });
  updateHeader();
  showPage('dashboard', document.querySelector('.nt'));
  renderDash();
}

export async function addFacility() {
  if (!ensurePageAccess('settings', 'settings-alert')) return;
  const name = sanitizeText(document.getElementById('af-name').value, 160);
  if (!name) { alert('Please enter the facility name.'); return; }
  const payload = {
    name,
    location: sanitizeText(document.getElementById('af-loc').value, 120),
    level: document.getElementById('af-level').value,
    email: sanitizeText(document.getElementById('af-email').value, 160),
    phone: sanitizeText(document.getElementById('af-phone').value, 40),
    token_rate: 200,
    financial_year: 2026,
  };
  const { data, error } = await createFacilityRecord(payload);
  if (error) { alert(error.message); return; }
  const f = makeFac(data);
  const newFacs = [...DB.facilities, f];
  setDB({ facilities: newFacs, activeFacId: f.id });
  sessionStorage.setItem('ohgl_active_facility', f.id);
  await audit('create', 'facilities', f.id, { name: f.name });
  closeModal('add-fac-modal');
  updateHeader();
  renderDash();
  ['af-name', 'af-loc', 'af-email', 'af-phone'].forEach(id => (document.getElementById(id).value = ''));
}

// ──── IAM Administration ───────────────────────────────────────────────────────

// All invitable roles (includes the two new ones)
const IAM_ROLES = ['super_admin', 'facility_manager', 'facility_officer', 'clinician', 'receptionist', 'monitor', 'chp'];
const INVITE_ROLES = ['clinician', 'receptionist', 'monitor', 'facility_manager', 'facility_officer'];
let iamUsers = [];
let iamAudit = [];

function iamRoleLabel(role) {
  return String(role || '').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function getFacilityLabel(facilityId) {
  const found = (DB.facilities || []).find(f => f.id === facilityId);
  return found ? `${found.location} - ${found.name}` : (facilityId || '-');
}

function renderFacilityOptions(selected = '') {
  return `<option value="">Select facility...</option>` + (DB.facilities || [])
    .map(f => `<option value="${h(f.id)}" ${f.id === selected ? 'selected' : ''}>${h(f.location)} - ${h(f.name)}</option>`)
    .join('');
}

function isApprovalDebugEnabled() {
  return window.location.hostname === 'localhost'
    || window.location.hostname === '127.0.0.1'
    || sessionStorage.getItem('ochp_debug_approval') === '1';
}

function logApprovalDebug(label, details) {
  if (isApprovalDebugEnabled()) console.debug(`[OCHP approval] ${label}`, details);
}

function renderRoleOptions(selected = '') {
  return IAM_ROLES
    .map(role => `<option value="${h(role)}" ${role === selected ? 'selected' : ''}>${h(iamRoleLabel(role))}</option>`)
    .join('');
}

function renderInviteRoleOptions() {
  return INVITE_ROLES
    .map(role => `<option value="${h(role)}">${h(iamRoleLabel(role))}</option>`)
    .join('');
}

function renderIamUserRows(users, isPending) {
  if (!users.length) return `<tr><td colspan="8" style="text-align:center;color:var(--MU)">No users found.</td></tr>`;
  return users.map(user => `
    <tr>
      <td><strong>${h(user.full_name || '-')}</strong><br><span class="muted-mini">${h(user.email || '')}</span></td>
      <td>${h(user.phone || '-')}</td>
      <td><span class="bdg bdg-t">${h(user.approval_status || '-')}</span></td>
      <td>${h(iamRoleLabel(user.role))}</td>
      <td>${h(getFacilityLabel(user.facility_id))}</td>
      <td>${h(user.chp_code_requested || '-')}</td>
      <td>${user.created_at ? h(new Date(user.created_at).toLocaleString()) : '-'}</td>
      <td style="min-width:260px">
        ${isPending ? `<select class="fi" id="iam-fac-${h(user.id)}" style="margin-bottom:6px" required>${renderFacilityOptions(user.facility_id)}</select><button type="button" class="btn btn-p btn-sm" data-iam-action="approve" data-user-id="${h(user.id)}"><i class="ti ti-check"></i> Approve</button> <button type="button" class="btn btn-d btn-sm" data-iam-action="reject" data-user-id="${h(user.id)}"><i class="ti ti-x"></i> Reject</button>` : ''}
        ${!isPending ? `<select class="fi" id="iam-role-${h(user.id)}" style="margin-bottom:6px">${renderRoleOptions(user.role)}</select><select class="fi" id="iam-fac-${h(user.id)}" style="margin-bottom:6px">${renderFacilityOptions(user.facility_id)}</select><button type="button" class="btn btn-s btn-sm" data-iam-action="change-role" data-user-id="${h(user.id)}">Role</button> <button type="button" class="btn btn-s btn-sm" data-iam-action="assign-facility" data-user-id="${h(user.id)}">Facility</button> <button type="button" class="btn btn-s btn-sm" data-iam-action="suspend" data-user-id="${h(user.id)}">Suspend</button> <button type="button" class="btn btn-s btn-sm" data-iam-action="reactivate" data-user-id="${h(user.id)}">Reactivate</button> <button type="button" class="btn btn-d btn-sm" data-iam-action="deactivate" data-user-id="${h(user.id)}">Deactivate</button>` : ''}
      </td>
    </tr>`).join('');
}

function renderIamAuditRows() {
  if (!iamAudit.length) return `<tr><td colspan="5" style="text-align:center;color:var(--MU)">No access audit events found.</td></tr>`;
  return iamAudit.slice(0, 15).map(evt => `
    <tr>
      <td>${evt.created_at ? h(new Date(evt.created_at).toLocaleString()) : '-'}</td>
      <td>${h(evt.action || '-')}</td>
      <td><code>${h(evt.target_user_id || '-')}</code></td>
      <td>${h(evt.reason || '-')}</td>
      <td><code>${h(JSON.stringify(evt.new_value || {}))}</code></td>
    </tr>`).join('');
}

function renderIamPanel() {
  const panel = document.getElementById('iam-admin-panel');
  if (!panel) return;
  const pending = iamUsers.filter(u => u.approval_status === 'pending');
  const allUsers = iamUsers.filter(u => u.approval_status !== 'pending');
  panel.style.display = 'block';

  // Populate invite form facility options
  const invFac = document.getElementById('inv-facility');
  if (invFac) invFac.innerHTML = renderFacilityOptions();

  panel.innerHTML = `
    <div id="iam-alert"></div>
    <div class="ch" style="display:flex;align-items:center;justify-content:space-between">
      <span class="ct"><i class="ti ti-shield-lock"></i> Identity &amp; Access Management</span>
      <button class="btn btn-p btn-sm" onclick="openModal('invite-staff-modal')"><i class="ti ti-user-plus"></i> Invite Staff</button>
    </div>
    <h4 style="margin:12px 0 8px">Pending Approval Queue</h4>
    <div style="overflow-x:auto"><table class="reg-tbl"><thead><tr><th>User</th><th>Phone</th><th>Status</th><th>Role</th><th>Facility</th><th>CHP Code</th><th>Registered</th><th>Actions</th></tr></thead><tbody>${renderIamUserRows(pending, true)}</tbody></table></div>
    <h4 style="margin:18px 0 8px">User Directory</h4>
    <div style="overflow-x:auto"><table class="reg-tbl"><thead><tr><th>User</th><th>Phone</th><th>Status</th><th>Role</th><th>Facility</th><th>CHP Code</th><th>Created</th><th>Actions</th></tr></thead><tbody>${renderIamUserRows(allUsers, false)}</tbody></table></div>
    <h4 style="margin:18px 0 8px">Recent Access Audit</h4>
    <div style="overflow-x:auto"><table class="reg-tbl"><thead><tr><th>Time</th><th>Action</th><th>Target User</th><th>Reason</th><th>New Value</th></tr></thead><tbody>${renderIamAuditRows()}</tbody></table></div>`;
  bindIamPanelEvents(panel);
}

function bindIamPanelEvents(panel) {
  panel.onclick = event => {
    const button = event.target.closest('[data-iam-action][data-user-id]');
    if (!button || !panel.contains(button)) return;
    const userId = button.dataset.userId;
    switch (button.dataset.iamAction) {
      case 'approve': iamApproveUser(userId); break;
      case 'reject': iamRejectUser(userId); break;
      case 'change-role': iamChangeRole(userId); break;
      case 'assign-facility': iamAssignFacility(userId); break;
      case 'suspend': iamSuspendUser(userId); break;
      case 'reactivate': iamReactivateUser(userId); break;
      case 'deactivate': iamDeactivateUser(userId); break;
    }
  };
}

function iamAlert(message, kind = 'alert-e') {
  const el = document.getElementById('iam-alert');
  if (el) el.innerHTML = `<div class="alert ${kind}">${h(message)}</div>`;
}

function iamErrorMessage(err, fallback) {
  const message = err?.message || fallback;
  if (/only super admin/i.test(message)) return 'Only Super Admin can manage user approvals and roles.';
  if (/valid facility/i.test(message)) return 'Select a valid facility before approving or assigning this user.';
  if (/pending users can be approved/i.test(message)) return 'This user is no longer pending and cannot be approved again.';
  if (/pending users can be rejected/i.test(message)) return 'This user is no longer pending and cannot be rejected.';
  if (/canonical|invalid role/i.test(message)) return 'Select a valid canonical role before saving.';
  if (/row-level security|permission denied|not authorized/i.test(message)) return 'You do not have permission to complete this IAM action.';
  return message || fallback;
}

async function refreshIamPanel() {
  const [{ data: users, error: usersErr }, { data: auditRows, error: auditErr }] = await Promise.all([
    listUsersSecure(),
    fetchUserAccessAudit(50),
  ]);
  if (usersErr) throw usersErr;
  if (auditErr) console.warn('IAM audit load failed', auditErr);
  iamUsers = users || [];
  iamAudit = auditRows || [];
  renderIamPanel();
}

function promptReason(action) {
  const reason = prompt(`Reason required to ${action}:`);
  return reason ? sanitizeText(reason, 500) : '';
}

export async function adminUserWizard() {
  if (!hasPerm('*')) {
    alert('Only Super Admin can access IAM administration.');
    return;
  }
  try {
    await refreshIamPanel();
  } catch (err) {
    alert(err.message || 'IAM users could not be loaded.');
  }
}

export async function iamApproveUser(userId) {
  const facilitySelect = document.getElementById(`iam-fac-${userId}`);
  const facilityId = facilitySelect?.value || '';
  const payload = { target_user_id: userId, facility_id: facilityId, reason: 'Approved from IAM admin UI' };
  logApprovalDebug('payload sent', payload);
  if (!payload.target_user_id) { iamAlert('Select a valid user before approving.'); return; }
  if (!payload.facility_id) { if (facilitySelect) facilitySelect.focus(); iamAlert('Select a facility before approving this user.'); return; }
  try {
    const { data, error } = await approveUserSecure(payload.target_user_id, payload.facility_id, payload.reason);
    logApprovalDebug('RPC response', data);
    if (error) throw error;
    iamAlert('User approved successfully.', 'alert-s');
    await Promise.all([refreshIamPanel(), refreshDB()]);
  } catch (err) {
    console.warn('IAM approval failed', { code: err?.code, details: err?.details, hint: err?.hint });
    iamAlert(iamErrorMessage(err, 'Approval failed. Please try again.'));
  }
}

export async function iamRejectUser(userId) {
  const reason = promptReason('reject this user');
  if (!reason) return iamAlert('Rejection reason is required.');
  try {
    const { error } = await rejectUserSecure(userId, reason);
    if (error) throw error;
    iamAlert('User rejected successfully.', 'alert-s');
    await refreshIamPanel();
  } catch (err) {
    console.warn('IAM rejection failed', { code: err?.code, details: err?.details, hint: err?.hint });
    iamAlert(iamErrorMessage(err, 'Rejection failed. Please try again.'));
  }
}

export async function iamSuspendUser(userId) {
  const reason = promptReason('suspend this user');
  if (!reason) return iamAlert('Suspension reason is required.');
  const { error } = await suspendUserSecure(userId, reason);
  if (error) return iamAlert(error.message);
  await refreshIamPanel();
}

export async function iamReactivateUser(userId) {
  const reason = promptReason('reactivate this user');
  if (!reason) return iamAlert('Reactivation reason is required.');
  const { error } = await reactivateUserSecure(userId, reason);
  if (error) return iamAlert(error.message);
  await refreshIamPanel();
}

export async function iamDeactivateUser(userId) {
  const reason = promptReason('deactivate this user');
  if (!reason) return iamAlert('Deactivation reason is required.');
  if (!confirm('Deactivate this user? This should be used for long-term access removal.')) return;
  const { error } = await deactivateUserSecure(userId, reason);
  if (error) return iamAlert(error.message);
  await refreshIamPanel();
}

export async function iamAssignFacility(userId) {
  const facilityId = document.getElementById(`iam-fac-${userId}`)?.value || '';
  if (!facilityId) return iamAlert('Select a facility before assigning this user.');
  const reason = promptReason('change this facility assignment');
  if (!reason) return iamAlert('Facility change reason is required.');
  try {
    const { error } = await assignUserFacilitySecure(userId, facilityId, reason);
    if (error) throw error;
    iamAlert('Facility assignment saved.', 'alert-s');
    await refreshIamPanel();
  } catch (err) {
    iamAlert(iamErrorMessage(err, 'Facility assignment failed. Please try again.'));
  }
}

export async function iamChangeRole(userId) {
  const role = document.getElementById(`iam-role-${userId}`)?.value || '';
  if (!IAM_ROLES.includes(role)) return iamAlert('Select a valid canonical role.');
  const reason = promptReason('change this user role');
  if (!reason) return iamAlert('Role change reason is required.');
  try {
    const { error } = await changeUserRoleSecure(userId, role, reason);
    if (error) throw error;
    iamAlert('Role updated successfully.', 'alert-s');
    await refreshIamPanel();
  } catch (err) {
    iamAlert(iamErrorMessage(err, 'Role update failed. Please try again.'));
  }
}

// ──── Invite Staff ─────────────────────────────────────────────────────────────

/** Called from the Invite Staff modal submit button. */
export async function inviteStaff() {
  if (!hasPerm('*')) {
    alert('Only Super Admin can invite staff.');
    return;
  }
  const alertEl = document.getElementById('invite-staff-alert');
  const btn = document.getElementById('invite-staff-btn');

  function invAlert(msg, kind = 'alert-e') {
    if (alertEl) alertEl.innerHTML = `<div class="alert ${kind}">${h(msg)}</div>`;
  }

  const email = sanitizeText(document.getElementById('inv-email')?.value?.trim() || '', 200);
  const fullName = sanitizeText(document.getElementById('inv-name')?.value?.trim() || '', 160);
  const role = document.getElementById('inv-role')?.value || '';
  const facilityId = document.getElementById('inv-facility')?.value || '';

  if (!email || !fullName || !role || !facilityId) {
    invAlert('All fields are required.');
    return;
  }
  if (!INVITE_ROLES.includes(role)) {
    invAlert('Select a valid role.');
    return;
  }

  if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Sending...'; }

  try {
    await inviteStaffUser(email, fullName, role, facilityId);
    invAlert(`Invitation sent to ${email}. They will receive a "Set your password" email to activate their account.`, 'alert-s');
    // Clear form
    ['inv-email', 'inv-name'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.value = '';
    });
    // Refresh user list in background
    refreshIamPanel().catch(console.warn);
  } catch (err) {
    invAlert(err.message || 'Invitation failed. Check that the Supabase service role key is configured on the API server.');
  } finally {
    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="ti ti-send"></i> Send Invitation'; }
  }
}

// ──── Data Management ──────────────────────────────────────────────────────────

export function exportJSON() {
  if (!ensurePageAccess('settings', 'settings-alert')) return;
  if (!hasPerm('audit:read')) { alert('Only administrators can export operational data.'); return; }
  const exportData = {
    generated_at: new Date().toISOString(),
    facilities: DB.facilities.map(f => ({
      ...f,
      referrals: (f.referrals || []).map(r => ({
        ...r,
        patient: '[REDACTED]',
        notes: '[REDACTED]',
        sha_no: '[REDACTED]',
      })),
    })),
  };
  const b = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(b);
  a.download = 'OHGL_CHP_Redacted_Export_' + new Date().toISOString().split('T')[0] + '.json';
  a.click();
}

export function importJSON(event) {
  const file = event.target?.files?.[0];
  if (!file) return;
  const allowedExtensions = /(\.json)$/i;
  if (!allowedExtensions.exec(file.name) || file.type !== 'application/json') {
    alert('Security Violation: Only valid JSON files (.json) are permitted.');
    event.target.value = '';
    return;
  }
  if (file.size > 2 * 1024 * 1024) {
    alert('Security Violation: File size exceeds the 2MB safety limit.');
    event.target.value = '';
    return;
  }
  const reader = new FileReader();
  reader.onload = function(e) {
    try {
      const data = JSON.parse(e.target.result);
      if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid JSON structure. Root must be a JSON object.');
      if (!Array.isArray(data.facilities)) throw new Error('Invalid schema structure. Missing "facilities" list.');
      for (const f of data.facilities) {
        if (!f.name || typeof f.name !== 'string') throw new Error('Schema Violation: Facility name is required.');
        if (!f.location || typeof f.location !== 'string') throw new Error('Schema Violation: Facility location is required.');
        // Use sanitizeText (wraps DOMPurify) instead of raw DOMPurify global
        f.name = sanitizeText(f.name.trim(), 160);
        f.location = sanitizeText(f.location.trim(), 120);
        if (f.chps && Array.isArray(f.chps)) {
          for (const c of f.chps) {
            if (!c.code) throw new Error('Schema Violation: CHP code is required.');
            if (!c.name) throw new Error('Schema Violation: CHP name is required.');
            c.code = sanitizeText(String(c.code).trim(), 40);
            c.name = sanitizeText(String(c.name).trim(), 160);
          }
        }
      }
      alert('Backup file check passed. Safe JSON schema detected. Proceed with migration via Supabase tools as outlined in docs/MIGRATION_PLAN.md.');
    } catch (err) {
      alert('Security/Validation Error: ' + err.message);
    } finally {
      event.target.value = '';
    }
  };
  reader.readAsText(file);
}
