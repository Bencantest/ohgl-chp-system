-- 20260705_000016_workflow_metadata_engine.sql
-- OCHP-002C.1 Workflow Metadata Engine.
-- Additive metadata RPC layer; does not alter workflow command behavior.

CREATE OR REPLACE FUNCTION get_workflow_action_definition(command_name text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  cmd text := lower(trim(coalesce(command_name, '')));
  def jsonb;
BEGIN
  def := CASE cmd
    WHEN 'submit_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'submit_referral_secure', 'label', 'Submit Referral', 'description', 'Submit this referral to the receiving facility.', 'category', 'Registration', 'confirmation', 'Submit this referral?', 'icon', 'send', 'color', 'primary', 'inputs', '[]'::jsonb, 'validation_messages', jsonb_build_object('unavailable', 'This referral cannot be submitted from its current state.'))
    WHEN 'accept_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'accept_referral_secure', 'label', 'Accept Referral', 'description', 'Accept this referral for facility handling.', 'category', 'Receiving', 'confirmation', 'Accept this referral?', 'icon', 'thumb-up', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'note', 'label', 'Receiving Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('unavailable', 'This referral must be submitted before it can be accepted.'))
    WHEN 'receive_patient' THEN jsonb_build_object('command', cmd, 'rpc_name', 'receive_patient_secure', 'label', 'Receive Patient', 'description', 'Record that the patient has arrived at the receiving point.', 'category', 'Receiving', 'confirmation', 'Mark this patient as received?', 'icon', 'login-2', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'received_by', 'label', 'Received By', 'type', 'text', 'required', false), jsonb_build_object('field', 'note', 'label', 'Receiving Note', 'type', 'textarea', 'required', false), jsonb_build_object('field', 'receiving_desk', 'label', 'Receiving Desk', 'type', 'select', 'required', false, 'source', 'receiving_desks')), 'validation_messages', jsonb_build_object('unavailable', 'This referral must first be accepted.'))
    WHEN 'assign_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'assign_referral_secure', 'label', 'Assign Referral', 'description', 'Assign this referral to a department or clinician.', 'category', 'Assignment', 'confirmation', 'Assign this referral?', 'icon', 'user-plus', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'department_id', 'label', 'Department', 'type', 'select', 'required', false, 'source', 'departments'), jsonb_build_object('field', 'assignee_user_id', 'label', 'Assigned User', 'type', 'select', 'required', false, 'source', 'facility_users'), jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'requires_any', jsonb_build_array('department_id', 'assignee_user_id'), 'validation_messages', jsonb_build_object('required', 'Select a department or assigned user, and provide a reason.', 'requires_any', 'Select a department or assigned user.') )
    WHEN 'transfer_department' THEN jsonb_build_object('command', cmd, 'rpc_name', 'transfer_department_secure', 'label', 'Transfer Department', 'description', 'Transfer this referral to another department.', 'category', 'Assignment', 'confirmation', 'Transfer this referral to another department?', 'icon', 'arrows-transfer-up', 'color', 'secondary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'department_id', 'label', 'Target Department', 'type', 'select', 'required', true, 'source', 'departments'), jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'validation_messages', jsonb_build_object('required', 'Target department and reason are required.'))
    WHEN 'transfer_facility' THEN jsonb_build_object('command', cmd, 'rpc_name', 'transfer_facility_secure', 'label', 'Transfer Facility', 'description', 'Transfer this referral to another facility.', 'category', 'Assignment', 'confirmation', 'Transfer this referral to another facility?', 'icon', 'building-hospital', 'color', 'secondary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'target_facility_id', 'label', 'Target Facility', 'type', 'select', 'required', true, 'source', 'facilities'), jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'validation_messages', jsonb_build_object('required', 'Target facility and reason are required.'))
    WHEN 'triage_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'triage_referral_secure', 'label', 'Triage Referral', 'description', 'Record triage for this referral.', 'category', 'Clinical', 'confirmation', 'Record triage for this referral?', 'icon', 'stethoscope', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'note', 'label', 'Triage Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('unavailable', 'This referral must first be received or assigned.'))
    WHEN 'start_consultation' THEN jsonb_build_object('command', cmd, 'rpc_name', 'start_consultation_secure', 'label', 'Start Consultation', 'description', 'Start clinical consultation.', 'category', 'Clinical', 'confirmation', 'Start consultation for this referral?', 'icon', 'clipboard-heart', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'note', 'label', 'Consultation Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('unavailable', 'This referral must first be triaged or assigned.'))
    WHEN 'record_investigation' THEN jsonb_build_object('command', cmd, 'rpc_name', 'record_investigation_secure', 'label', 'Record Investigation', 'description', 'Record investigation notes.', 'category', 'Clinical', 'confirmation', 'Record investigation details?', 'icon', 'microscope', 'color', 'secondary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'note', 'label', 'Investigation Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('unavailable', 'Consultation must be active before investigation can be recorded.'))
    WHEN 'record_treatment' THEN jsonb_build_object('command', cmd, 'rpc_name', 'record_treatment_secure', 'label', 'Record Treatment', 'description', 'Record treatment details.', 'category', 'Clinical', 'confirmation', 'Record treatment details?', 'icon', 'first-aid-kit', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'note', 'label', 'Treatment Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('unavailable', 'Treatment can only be recorded from consultation.'))
    WHEN 'record_outcome' THEN jsonb_build_object('command', cmd, 'rpc_name', 'record_outcome_secure', 'label', 'Record Outcome', 'description', 'Record the referral outcome.', 'category', 'Outcome', 'confirmation', 'Record outcome for this referral?', 'icon', 'circle-check', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'outcome', 'label', 'Outcome', 'type', 'select', 'required', true, 'source', 'outcome_types'), jsonb_build_object('field', 'note', 'label', 'Outcome Note', 'type', 'textarea', 'required', false)), 'validation_messages', jsonb_build_object('required', 'Outcome is required.'))
    WHEN 'complete_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'complete_referral_secure', 'label', 'Complete Referral', 'description', 'Complete this referral.', 'category', 'Closure', 'confirmation', 'Are you sure you want to complete this referral? Completed referrals can only be reopened by authorized users.', 'icon', 'discount-check', 'color', 'success', 'inputs', jsonb_build_array(jsonb_build_object('field', 'outcome', 'label', 'Outcome', 'type', 'select', 'required', true, 'source', 'outcome_types')), 'validation_messages', jsonb_build_object('required', 'Outcome is required before completing a referral.'))
    WHEN 'close_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'close_referral_secure', 'label', 'Close Referral', 'description', 'Close a completed referral.', 'category', 'Closure', 'confirmation', 'Close this referral?', 'icon', 'lock', 'color', 'secondary', 'inputs', '[]'::jsonb, 'validation_messages', jsonb_build_object('unavailable', 'Only completed referrals can be closed.'))
    WHEN 'cancel_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'cancel_referral_secure', 'label', 'Cancel Referral', 'description', 'Cancel this referral.', 'category', 'Closure', 'confirmation', 'Cancel this referral? This will stop the active workflow.', 'icon', 'circle-x', 'color', 'danger', 'inputs', jsonb_build_array(jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'validation_messages', jsonb_build_object('required', 'Reason is required to cancel a referral.'))
    WHEN 'reopen_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'reopen_referral_secure', 'label', 'Reopen Referral', 'description', 'Reopen a closed or cancelled referral.', 'category', 'Closure', 'confirmation', 'Reopen this referral?', 'icon', 'refresh', 'color', 'primary', 'inputs', jsonb_build_array(jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'validation_messages', jsonb_build_object('required', 'Reason is required to reopen a referral.'))
    WHEN 'archive_referral' THEN jsonb_build_object('command', cmd, 'rpc_name', 'archive_referral_secure', 'label', 'Archive Referral', 'description', 'Archive this referral.', 'category', 'Archive', 'confirmation', 'Archive this referral? Archived referrals cannot be modified.', 'icon', 'archive', 'color', 'danger', 'inputs', jsonb_build_array(jsonb_build_object('field', 'reason', 'label', 'Reason', 'type', 'textarea', 'required', true)), 'validation_messages', jsonb_build_object('required', 'Reason is required to archive a referral.'))
    ELSE NULL
  END;

  IF def IS NULL THEN
    RAISE EXCEPTION 'Unknown workflow command: %', command_name;
  END IF;
  RETURN def;
END;
$$;

CREATE OR REPLACE FUNCTION get_workflow_reference_data(command_name text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  def jsonb := public.get_workflow_action_definition(command_name);
  sources text[];
  fid uuid := public.current_user_facility();
  result jsonb := '{}'::jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.';
  END IF;

  SELECT array_agg(DISTINCT input->>'source') INTO sources
  FROM jsonb_array_elements(coalesce(def->'inputs', '[]'::jsonb)) input
  WHERE input ? 'source';

  IF sources IS NULL THEN
    RETURN result;
  END IF;

  IF 'departments' = ANY(sources) THEN
    result := result || jsonb_build_object('departments', coalesce((
      SELECT jsonb_agg(jsonb_build_object('value', d.id, 'label', d.department_name, 'code', d.department_code) ORDER BY d.department_name)
      FROM departments d
      WHERE d.active = true AND (public.current_user_role() = 'super_admin'::app_role OR d.facility_id = fid)
    ), '[]'::jsonb));
  END IF;

  IF 'facility_users' = ANY(sources) THEN
    result := result || jsonb_build_object('facility_users', coalesce((
      SELECT jsonb_agg(jsonb_build_object('value', u.id, 'label', u.full_name, 'role', u.role) ORDER BY u.full_name)
      FROM users u
      WHERE u.active = true
        AND u.approval_status = 'approved'
        AND u.role IN ('facility_manager'::app_role, 'facility_officer'::app_role)
        AND (public.current_user_role() = 'super_admin'::app_role OR u.facility_id = fid)
    ), '[]'::jsonb));
  END IF;

  IF 'facilities' = ANY(sources) THEN
    result := result || jsonb_build_object('facilities', coalesce((
      SELECT jsonb_agg(jsonb_build_object('value', f.id, 'label', f.name, 'location', f.location) ORDER BY f.location, f.name)
      FROM facilities f
      WHERE public.current_user_role() = 'super_admin'::app_role OR f.id <> fid
    ), '[]'::jsonb));
  END IF;

  IF 'receiving_desks' = ANY(sources) THEN
    result := result || jsonb_build_object('receiving_desks', jsonb_build_array(
      jsonb_build_object('value', 'opd', 'label', 'OPD'),
      jsonb_build_object('value', 'triage', 'label', 'Triage'),
      jsonb_build_object('value', 'reception', 'label', 'Reception')
    ));
  END IF;

  IF 'outcome_types' = ANY(sources) THEN
    result := result || jsonb_build_object('outcome_types', (
      SELECT jsonb_agg(jsonb_build_object('value', outcome::text, 'label', initcap(replace(outcome::text, '_', ' '))) ORDER BY outcome::text)
      FROM unnest(enum_range(NULL::referral_outcome)) outcome
      WHERE outcome <> 'unknown'::referral_outcome
    ));
  END IF;

  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION get_available_referral_actions(referral_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec referrals;
  commands text[] := ARRAY[]::text[];
  action jsonb;
  actions jsonb := '[]'::jsonb;
  cmd text;
  can_update boolean;
  can_complete boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.';
  END IF;

  SELECT * INTO rec
  FROM referrals r
  WHERE r.id = referral_id;

  IF rec.id IS NULL THEN
    RAISE EXCEPTION 'Referral not found.';
  END IF;

  PERFORM public.validate_referral_owner(rec);

  can_update := public.has_permission('referral:update_facility') OR public.has_permission('referral:update');
  can_complete := public.has_permission('referral:complete') OR public.has_permission('referral:update');

  commands := CASE rec.referral_status
    WHEN 'draft' THEN ARRAY['submit_referral', 'cancel_referral']
    WHEN 'submitted' THEN ARRAY['accept_referral', 'cancel_referral']
    WHEN 'accepted' THEN ARRAY['receive_patient', 'assign_referral', 'triage_referral', 'cancel_referral']
    WHEN 'received' THEN ARRAY['assign_referral', 'triage_referral', 'cancel_referral']
    WHEN 'assigned' THEN ARRAY['assign_referral', 'transfer_department', 'triage_referral', 'start_consultation', 'cancel_referral']
    WHEN 'triaged' THEN ARRAY['assign_referral', 'transfer_department', 'start_consultation', 'cancel_referral']
    WHEN 'in_consultation' THEN ARRAY['record_investigation', 'record_treatment', 'record_outcome', 'cancel_referral']
    WHEN 'treatment' THEN ARRAY['record_outcome', 'complete_referral', 'cancel_referral']
    WHEN 'outcome_recorded' THEN ARRAY['complete_referral', 'cancel_referral']
    WHEN 'completed' THEN ARRAY['close_referral', 'reopen_referral']
    WHEN 'closed' THEN ARRAY['reopen_referral', 'archive_referral']
    WHEN 'cancelled' THEN ARRAY['reopen_referral', 'archive_referral']
    WHEN 'reopened' THEN ARRAY['accept_referral', 'receive_patient', 'assign_referral', 'triage_referral', 'cancel_referral']
    ELSE ARRAY[]::text[]
  END;

  FOREACH cmd IN ARRAY commands LOOP
    action := public.get_workflow_action_definition(cmd);
    IF cmd IN ('complete_referral', 'close_referral', 'archive_referral') THEN
      action := action || jsonb_build_object('enabled', can_complete);
    ELSIF cmd = 'submit_referral' THEN
      action := action || jsonb_build_object('enabled', public.has_permission('referral:create'));
    ELSE
      action := action || jsonb_build_object('enabled', can_update);
    END IF;
    actions := actions || jsonb_build_array(action);
  END LOOP;

  RETURN jsonb_build_object(
    'status', rec.referral_status,
    'stage', rec.referral_stage,
    'owner', rec.current_owner_type,
    'owner_facility_id', rec.current_owner_facility_id,
    'owner_user_id', rec.current_owner_user_id,
    'department', rec.current_owner_department,
    'available_actions', actions
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION get_workflow_action_definition(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION get_workflow_reference_data(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION get_available_referral_actions(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_workflow_action_definition(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_workflow_reference_data(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_referral_actions(uuid) TO authenticated;


