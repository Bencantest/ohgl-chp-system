DO $$
BEGIN
  ALTER TABLE public.user_access_audit
    DROP CONSTRAINT IF EXISTS user_access_audit_action_check;

  ALTER TABLE public.user_access_audit
    ADD CONSTRAINT user_access_audit_action_check
    CHECK (action IN (
      'approve',
      'reject',
      'suspend',
      'reactivate',
      'deactivate',
      'assign_facility',
      'change_role',
      'reconcile_profile'
    ));
END $$;
-- 20260705_000012_auth_profile_reconciliation.sql
-- OCHP Sprint 1 Final Hotfix: reconcile auth.users records missing public.users profiles.
-- Forward-only, idempotent, and non-destructive.

WITH created_profiles AS (
  INSERT INTO public.users (
    id,
    facility_id,
    role,
    full_name,
    email,
    phone,
    active,
    approval_status,
    chp_code_requested
  )
  SELECT
    au.id,
    null,
    'chp'::app_role,
    coalesce(
      nullif(trim(coalesce(au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', '')), ''),
      split_part(au.email, '@', 1),
      au.email,
      'Unprovisioned User'
    ),
    au.email,
    nullif(trim(coalesce(au.raw_user_meta_data->>'phone', au.phone, '')), ''),
    false,
    'pending'::user_approval_status,
    nullif(trim(coalesce(au.raw_user_meta_data->>'chp_code_requested', au.raw_user_meta_data->>'chp_code', '')), '')
  FROM auth.users au
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.users pu
    WHERE pu.id = au.id
  )
  RETURNING id, role, approval_status, facility_id, active
)
INSERT INTO public.user_access_audit (
  actor_id,
  target_user_id,
  action,
  old_value,
  new_value,
  reason
)
SELECT
  null,
  cp.id,
  'reconcile_profile',
  '{}'::jsonb,
  jsonb_build_object(
    'role', cp.role,
    'approval_status', cp.approval_status,
    'facility_id', cp.facility_id,
    'active', cp.active
  ),
  'Auth profile reconciliation: created missing pending CHP profile for existing auth user.'
FROM created_profiles cp;

