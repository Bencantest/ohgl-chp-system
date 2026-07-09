import {
  executeReferralCommand,
  fetchReferralAssignmentHistory,
  fetchReferralClinicalNotes,
  fetchReferralEvents,
  fetchReferralSla,
  getAvailableReferralActions,
  getWorkflowActionDefinition,
  getWorkflowReferenceData,
} from './dataService.js';
import { refreshDB } from '../main.js';
import { h, sanitizeText } from '../utils/sanitize.js';

function normalizeActionResponse(data) {
  const body = Array.isArray(data) ? data[0] : data;
  return body || { available_actions: [] };
}

function optionList(input, referenceData) {
  const values = referenceData?.[input.source] || input.options || [];
  return Array.isArray(values) ? values : [];
}

function inputControl(input, referenceData) {
  const required = input.required ? 'required' : '';
  const field = h(input.field);
  const label = h(input.label || input.field);
  const valueAttr = input.default_value ? ` value="${h(input.default_value)}"` : '';

  if (input.type === 'textarea') {
    return `<label class="wf-form-field"><span>${label}${input.required ? ' *' : ''}</span><textarea class="fi" name="${field}" ${required}></textarea></label>`;
  }

  if (input.type === 'select') {
    const options = optionList(input, referenceData).map(opt => `<option value="${h(opt.value)}">${h(opt.label || opt.name || opt.value)}</option>`).join('');
    return `<label class="wf-form-field"><span>${label}${input.required ? ' *' : ''}</span><select class="fi" name="${field}" ${required}><option value=""></option>${options}</select></label>`;
  }

  return `<label class="wf-form-field"><span>${label}${input.required ? ' *' : ''}</span><input class="fi" name="${field}" type="${h(input.type || 'text')}" ${required}${valueAttr}></label>`;
}

function buildPayload(form, inputs) {
  return (inputs || []).reduce((payload, input) => {
    const el = form.elements[input.field];
    const value = sanitizeText(el?.value || '', input.type === 'textarea' ? 2000 : 500);
    if (value) payload[input.field] = value;
    return payload;
  }, {});
}

function validatePayload(payload, action) {
  const inputs = action.inputs || [];
  const missing = inputs.filter(input => input.required && !payload[input.field]);
  if (missing.length) {
    return action.validation_messages?.required || `${missing.map(input => input.label || input.field).join(', ')} required.`;
  }
  if (Array.isArray(action.requires_any) && action.requires_any.length && !action.requires_any.some(field => payload[field])) {
    return action.validation_messages?.requires_any || action.validation_messages?.required || '';
  }
  return '';
}

function openWorkflowDialog(action, referenceData) {
  return new Promise(resolve => {
    const inputs = action.inputs || [];
    const overlay = document.createElement('div');
    overlay.className = 'wf-dialog-backdrop';
    overlay.innerHTML = `<div class="wf-dialog" role="dialog" aria-modal="true">
      <div class="wf-dialog-head">
        <div><strong>${h(action.label)}</strong><p>${h(action.description || '')}</p></div>
        <button type="button" class="wf-dialog-x" aria-label="Close"><i class="ti ti-x"></i></button>
      </div>
      <form class="wf-dialog-body">
        <div class="wf-dialog-confirm">${h(action.confirmation || '')}</div>
        ${inputs.map(input => inputControl(input, referenceData)).join('')}
        <div class="wf-dialog-error" aria-live="polite"></div>
        <div class="wf-dialog-actions">
          <button type="button" class="btn btn-s btn-sm" data-cancel="true">Cancel</button>
          <button type="submit" class="btn btn-t btn-sm"><i class="ti ti-check"></i>${h(action.label)}</button>
        </div>
      </form>
    </div>`;

    const close = value => {
      overlay.remove();
      resolve(value);
    };
    overlay.querySelector('[data-cancel]').addEventListener('click', () => close(null));
    overlay.querySelector('.wf-dialog-x').addEventListener('click', () => close(null));
    overlay.addEventListener('click', event => {
      if (event.target === overlay) close(null);
    });
    overlay.querySelector('form').addEventListener('submit', event => {
      event.preventDefault();
      const payload = buildPayload(event.currentTarget, inputs);
      const validation = validatePayload(payload, action);
      const errorEl = overlay.querySelector('.wf-dialog-error');
      if (validation) {
        errorEl.textContent = validation;
        return;
      }
      close(payload);
    });
    document.body.appendChild(overlay);
    const first = overlay.querySelector('input,select,textarea,button');
    if (first) first.focus();
  });
}

export const workflowActionService = {
  async loadAvailableActions(referralId) {
    const { data, error } = await getAvailableReferralActions(referralId);
    if (error) throw error;
    return normalizeActionResponse(data);
  },

  async loadActionDefinition(commandName) {
    const { data, error } = await getWorkflowActionDefinition(commandName);
    if (error) throw error;
    return Array.isArray(data) ? data[0] : data;
  },

  async loadReferenceData(commandName) {
    const { data, error } = await getWorkflowReferenceData(commandName);
    if (error) throw error;
    return Array.isArray(data) ? data[0] : (data || {});
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
    const definition = action.rpc_name ? action : await this.loadActionDefinition(action.command);
    if (!definition?.rpc_name) throw new Error(definition?.validation_messages?.unavailable || 'Workflow command metadata is incomplete.');
    const referenceData = await this.loadReferenceData(definition.command);
    const payload = await openWorkflowDialog(definition, referenceData);
    if (payload === null) return { cancelled: true };
    const { error } = await executeReferralCommand(definition.rpc_name, referralId, payload);
    if (error) throw error;
    await refreshDB();
    return { success: true };
  },
};

