import { h } from '../utils/sanitize.js';

function fmtDate(value) {
  if (!value) return '-';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return h(value);
  return d.toLocaleString([], { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' });
}

function titleize(value) {
  return h(String(value || '-').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()));
}

export function renderReferralHeader(ref, actionState = {}) {
  return `<div class="wf-header">
    <div><div class="wf-kicker">Referral</div><div class="wf-title">${h(ref.id || '-')}</div></div>
    <div class="wf-badges">
      <span class="bdg bdg-t">${h(actionState.status || ref.referral_status || ref.workflow_status || ref.status || 'Submitted')}</span>
      <span class="bdg bdg-p">${h(actionState.stage || ref.referral_stage || ref.stage || 'registration')}</span>
    </div>
  </div>`;
}

export function renderPatientSummary(ref) {
  return `<div class="wf-card"><div class="wf-card-title"><i class="ti ti-user"></i> Patient Summary</div>
    <div class="wf-fields">
      <span><b>Name</b>${h(ref.patient || '-')}</span><span><b>National ID</b>${h(ref.national_id || '-')}</span>
      <span><b>Age / Sex</b>${h(ref.age || '-')}/${h(ref.sex || '-')}</span><span><b>Phone</b>${h(ref.phone || '-')}</span>
    </div></div>`;
}

export function renderReferralDetails(ref) {
  return `<div class="wf-card"><div class="wf-card-title"><i class="ti ti-file-description"></i> Referral Details</div>
    <div class="wf-fields">
      <span><b>Priority</b>${h(ref.priority || '-')}</span><span><b>Category</b>${h(ref.category || '-')}</span>
      <span><b>Department</b>${h(ref.department || '-')}</span><span><b>Facility</b>${h(ref.referral_facility || '-')}</span>
      <span class="wf-wide"><b>Reason</b>${h(ref.referral_reason || '-')}</span>
    </div></div>`;
}

export function renderCurrentStatusCard(ref, actionState = {}) {
  return `<div class="wf-card"><div class="wf-card-title"><i class="ti ti-activity"></i> Current Status</div>
    <div class="wf-stat">${h(actionState.status || ref.referral_status || ref.workflow_status || ref.status || 'Submitted')}</div>
    <div class="muted-mini">Stage: ${h(actionState.stage || ref.referral_stage || ref.stage || '-')}</div></div>`;
}

export function renderCurrentOwnerCard(ref, actionState = {}) {
  return `<div class="wf-card"><div class="wf-card-title"><i class="ti ti-building-hospital"></i> Current Owner</div>
    <div class="wf-stat">${h(actionState.owner || ref.current_owner_type || 'facility')}</div>
    <div class="muted-mini">Department: ${h(ref.current_owner_department || ref.department || '-')}</div></div>`;
}

export function renderSlaCard(sla = []) {
  const active = sla.find(x => !x.completed_at) || sla[0];
  const label = active?.breached ? 'Breached' : active?.completed_at ? 'Met' : active?.target_at ? 'Active' : 'Not set';
  return `<div class="wf-card"><div class="wf-card-title"><i class="ti ti-clock-hour-4"></i> SLA</div>
    <div class="wf-stat">${h(label)}</div><div class="muted-mini">${active ? `${titleize(active.transition_name)} due ${fmtDate(active.target_at)}` : 'No SLA timers found.'}</div></div>`;
}

export function renderWorkflowActionPanel(ref, actionState = {}, loading = false) {
  const actions = Array.isArray(actionState.available_actions) ? actionState.available_actions : [];
  if (loading) return `<div class="wf-card wf-actions"><div class="wf-card-title"><i class="ti ti-player-play"></i> Workflow Actions</div><div class="muted-mini">Loading available actions...</div></div>`;
  const groups = actions.reduce((acc, action) => {
    const category = action.category || '';
    if (!acc.has(category)) acc.set(category, []);
    acc.get(category).push(action);
    return acc;
  }, new Map());
  const buttons = [...groups.entries()].map(([category, groupActions]) => `<div class="wf-action-group">${category ? `<div class="wf-action-category">${h(category)}</div>` : ''}<div class="wf-action-row">${groupActions.map(a => {
    const color = a.color ? ` wf-action-${h(a.color)}` : '';
    const icon = a.icon ? `<i class="ti ti-${h(a.icon)}"></i>` : '';
    return `<button class="btn btn-sm wf-action-btn${color}" ${a.enabled === false ? 'disabled' : ''} title="${h(a.description || '')}" onclick="executeReferralWorkflowAction('${h(ref.db_id)}','${h(a.command)}')">${icon}${h(a.label)}</button>`;
  }).join('')}</div></div>`).join('');
  return `<div class="wf-card wf-actions"><div class="wf-card-title"><i class="ti ti-player-play"></i> Workflow Actions</div>
    ${buttons || '<span class="muted-mini">No workflow actions are available.</span>'}</div>`;
}

export function renderTimeline(events = []) {
  const rows = events.map(e => `<div class="wf-event"><div><b>${titleize(e.event_name)}</b><span>${fmtDate(e.created_at)}</span></div><div>${h(e.actor?.full_name || 'System')} ${e.actor_role ? `(${h(e.actor_role)})` : ''}<br><small>${h(e.facility?.name || '-')} / ${h(e.department || '-')}</small>${e.reason ? `<p>${h(e.reason)}</p>` : ''}</div></div>`).join('');
  return `<div class="wf-card wf-wide"><div class="wf-card-title"><i class="ti ti-timeline-event"></i> Timeline</div>${rows || '<div class="muted-mini">No timeline events found.</div>'}</div>`;
}

export function renderClinicalNotes(notes = []) {
  const groups = ['chp', 'receiving', 'triage', 'consultation', 'investigation', 'treatment', 'outcome', 'follow_up'];
  const body = groups.map(group => {
    const items = notes.filter(n => n.note_type === group);
    return `<details class="wf-note-group" ${items.length ? 'open' : ''}><summary>${titleize(group)} <span>${items.length}</span></summary>${items.map(n => `<div class="wf-note"><b>v${h(n.version)} by ${h(n.author?.full_name || n.author_role || '-')}</b><small>${fmtDate(n.created_at)}</small><p>${h(n.note_text || '')}</p></div>`).join('') || '<div class="muted-mini">No notes.</div>'}</details>`;
  }).join('');
  return `<div class="wf-card wf-wide"><div class="wf-card-title"><i class="ti ti-notes"></i> Clinical Notes</div>${body}</div>`;
}

export function renderAssignmentHistory(assignments = []) {
  const rows = assignments.map(a => `<div class="wf-event"><div><b>${titleize(a.assignment_type)}</b><span>${fmtDate(a.created_at)}</span></div><div>${titleize(a.previous_owner_type)} -> ${titleize(a.new_owner_type)}<br><small>${h(a.previous_department || '-')} -> ${h(a.new_department || '-')} by ${h(a.actor?.full_name || '-')}</small>${a.reason ? `<p>${h(a.reason)}</p>` : ''}</div></div>`).join('');
  return `<div class="wf-card wf-wide"><div class="wf-card-title"><i class="ti ti-route"></i> Assignment History</div>${rows || '<div class="muted-mini">No assignment history found.</div>'}</div>`;
}

export function renderWorkflowBundle(ref, actionState = {}, artifacts = {}, loadingActions = false) {
  return `<div class="wf-bundle">
    ${renderReferralHeader(ref, actionState)}
    <div class="wf-grid">
      ${renderPatientSummary(ref)}${renderReferralDetails(ref)}${renderCurrentStatusCard(ref, actionState)}${renderCurrentOwnerCard(ref, actionState)}${renderSlaCard(artifacts.sla || [])}${renderWorkflowActionPanel(ref, actionState, loadingActions)}
      ${renderTimeline(artifacts.timeline || [])}${renderClinicalNotes(artifacts.clinicalNotes || [])}${renderAssignmentHistory(artifacts.assignmentHistory || [])}
    </div>
  </div>`;
}




