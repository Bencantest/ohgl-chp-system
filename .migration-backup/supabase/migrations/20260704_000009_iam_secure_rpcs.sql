-- 20260704_000009_iam_secure_rpcs.sql
-- OCHP Sprint 1 Task 4: secure Identity & Access RPC layer.

CREATE OR REPLACE FUNCTION assert_super_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only Super Admin can perform this action.';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION require_iam_reason(p_reason text, p_action text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  cleaned text := nullif(trim(coalesce(p_reason, '')), '');
BEGIN
  IF cleaned IS NULL THEN
    RAISE EXCEPTION 'A reason is required to % a user.', p_action;
  END IF;
  RETURN cleaned;
END;
$$;

CREATE OR REPLACE FUNCTION write_user_access_audit(
  p_target_user_id uuid,
  p_action text,
  p_old_value jsonb,
  p_new_value jsonb,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_access_audit (
    actor_id,
    target_user_id,
    action,
    old_value,
    new_value,
    reason
  )
  VALUES (
    auth.uid(),
    p_target_user_id,
    p_action,
    coalesce(p_old_value, '{}'::jsonb),
    coalesce(p_new_value, '{}'::jsonb),
    nullif(trim(coalesce(p_reason, '')), '')
  );
END;
$$;

CREATE OR REPLACE FUNCTION approve_user_secure(target_user_id uuid, facility_id uuid, reason text DEFAULT NULL)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_facility_id ALIAS FOR $2;
  p_reason ALIAS FOR $3;
  before_rec users;
  after_rec users;
BEGIN
  PERFORM public.assert_super_admin();

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Users cannot approve themselves.';
  END IF;
  IF p_facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM facilities f WHERE f.id = p_facility_id) THEN
    RAISE EXCEPTION 'A valid facility is required to approve this user.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;
  IF before_rec.approval_status <> 'pending'::user_approval_status THEN
    RAISE EXCEPTION 'Only pending users can be approved.';
  END IF;

  UPDATE users u
  SET approval_status = 'approved'::user_approval_status,
      facility_id = p_facility_id,
      active = true,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'approve',
    jsonb_build_object('approval_status', before_rec.approval_status, 'facility_id', before_rec.facility_id, 'active', before_rec.active),
    jsonb_build_object('approval_status', after_rec.approval_status, 'facility_id', after_rec.facility_id, 'active', after_rec.active),
    p_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION reject_user_secure(target_user_id uuid, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_reason ALIAS FOR $2;
  before_rec users;
  after_rec users;
  cleaned_reason text;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'reject');

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Users cannot reject themselves.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;
  IF before_rec.approval_status <> 'pending'::user_approval_status THEN
    RAISE EXCEPTION 'Only pending users can be rejected.';
  END IF;

  UPDATE users u
  SET approval_status = 'rejected'::user_approval_status,
      active = false,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'reject',
    jsonb_build_object('approval_status', before_rec.approval_status, 'active', before_rec.active),
    jsonb_build_object('approval_status', after_rec.approval_status, 'active', after_rec.active),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION suspend_user_secure(target_user_id uuid, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_reason ALIAS FOR $2;
  before_rec users;
  after_rec users;
  cleaned_reason text;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'suspend');

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Users cannot suspend themselves.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;
  IF before_rec.approval_status <> 'approved'::user_approval_status THEN
    RAISE EXCEPTION 'Only approved users can be suspended.';
  END IF;

  UPDATE users u
  SET approval_status = 'suspended'::user_approval_status,
      active = false,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'suspend',
    jsonb_build_object('approval_status', before_rec.approval_status, 'active', before_rec.active),
    jsonb_build_object('approval_status', after_rec.approval_status, 'active', after_rec.active),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION reactivate_user_secure(target_user_id uuid, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_reason ALIAS FOR $2;
  before_rec users;
  after_rec users;
  cleaned_reason text;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'reactivate');

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Users cannot reactivate themselves.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;
  IF before_rec.approval_status <> 'suspended'::user_approval_status THEN
    RAISE EXCEPTION 'Only suspended users can be reactivated.';
  END IF;

  UPDATE users u
  SET approval_status = 'approved'::user_approval_status,
      active = true,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'reactivate',
    jsonb_build_object('approval_status', before_rec.approval_status, 'active', before_rec.active),
    jsonb_build_object('approval_status', after_rec.approval_status, 'active', after_rec.active),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION deactivate_user_secure(target_user_id uuid, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_reason ALIAS FOR $2;
  before_rec users;
  after_rec users;
  cleaned_reason text;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'deactivate');

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Super Admin cannot self-deactivate through this workflow.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;
  IF before_rec.approval_status NOT IN ('approved'::user_approval_status, 'suspended'::user_approval_status) THEN
    RAISE EXCEPTION 'Only approved or suspended users can be deactivated.';
  END IF;

  UPDATE users u
  SET approval_status = 'deactivated'::user_approval_status,
      active = false,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'deactivate',
    jsonb_build_object('approval_status', before_rec.approval_status, 'active', before_rec.active),
    jsonb_build_object('approval_status', after_rec.approval_status, 'active', after_rec.active),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION assign_user_facility_secure(target_user_id uuid, facility_id uuid, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_facility_id ALIAS FOR $2;
  p_reason ALIAS FOR $3;
  before_rec users;
  after_rec users;
  cleaned_reason text;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'change facility assignment for');

  IF p_facility_id IS NULL OR NOT EXISTS (SELECT 1 FROM facilities f WHERE f.id = p_facility_id) THEN
    RAISE EXCEPTION 'A valid facility is required.';
  END IF;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;

  UPDATE users u
  SET facility_id = p_facility_id,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'assign_facility',
    jsonb_build_object('facility_id', before_rec.facility_id),
    jsonb_build_object('facility_id', after_rec.facility_id),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION change_user_role_secure(target_user_id uuid, new_role text, reason text)
RETURNS users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  p_target_user_id ALIAS FOR $1;
  p_new_role ALIAS FOR $2;
  p_reason ALIAS FOR $3;
  before_rec users;
  after_rec users;
  cleaned_reason text;
  canonical_role app_role;
BEGIN
  PERFORM public.assert_super_admin();
  cleaned_reason := public.require_iam_reason(p_reason, 'change role for');

  IF p_target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Super Admin cannot change their own role through this workflow.';
  END IF;
  IF p_new_role NOT IN ('super_admin', 'facility_manager', 'facility_officer', 'clinician', 'chp') THEN
    RAISE EXCEPTION 'Invalid role. Use a canonical OCHP role.';
  END IF;

  canonical_role := p_new_role::app_role;

  SELECT * INTO before_rec FROM users u WHERE u.id = p_target_user_id FOR UPDATE;
  IF before_rec.id IS NULL THEN
    RAISE EXCEPTION 'Target user was not found.';
  END IF;

  UPDATE users u
  SET role = canonical_role,
      updated_at = now()
  WHERE u.id = p_target_user_id
  RETURNING * INTO after_rec;

  PERFORM public.write_user_access_audit(
    p_target_user_id,
    'change_role',
    jsonb_build_object('role', before_rec.role),
    jsonb_build_object('role', after_rec.role),
    cleaned_reason
  );

  RETURN after_rec;
END;
$$;

CREATE OR REPLACE FUNCTION list_pending_users_secure()
RETURNS TABLE (
  id uuid,
  full_name text,
  email citext,
  phone text,
  role app_role,
  facility_id uuid,
  approval_status user_approval_status,
  chp_code_requested text,
  active boolean,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_super_admin();

  RETURN QUERY
  SELECT u.id, u.full_name, u.email, u.phone, u.role, u.facility_id, u.approval_status,
         u.chp_code_requested, u.active, u.created_at, u.updated_at
  FROM users u
  WHERE u.approval_status = 'pending'::user_approval_status
  ORDER BY u.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION list_users_secure()
RETURNS TABLE (
  id uuid,
  full_name text,
  email citext,
  phone text,
  role app_role,
  facility_id uuid,
  approval_status user_approval_status,
  chp_code_requested text,
  active boolean,
  created_at timestamptz,
  updated_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_super_admin();

  RETURN QUERY
  SELECT u.id, u.full_name, u.email, u.phone, u.role, u.facility_id, u.approval_status,
         u.chp_code_requested, u.active, u.created_at, u.updated_at
  FROM users u
  ORDER BY u.created_at DESC;
END;
$$;

REVOKE EXECUTE ON FUNCTION assert_super_admin() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION require_iam_reason(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION write_user_access_audit(uuid, text, jsonb, jsonb, text) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION approve_user_secure(uuid, uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION reject_user_secure(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION suspend_user_secure(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION reactivate_user_secure(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION deactivate_user_secure(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION assign_user_facility_secure(uuid, uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION change_user_role_secure(uuid, text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION list_pending_users_secure() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION list_users_secure() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION approve_user_secure(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_user_secure(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION suspend_user_secure(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION reactivate_user_secure(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION deactivate_user_secure(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_user_facility_secure(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION change_user_role_secure(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION list_pending_users_secure() TO authenticated;
GRANT EXECUTE ON FUNCTION list_users_secure() TO authenticated;
