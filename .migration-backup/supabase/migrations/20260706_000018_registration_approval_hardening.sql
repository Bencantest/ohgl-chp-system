-- 20260706_000018_registration_approval_hardening.sql
-- Hardens self-registration so auth-created users are always CHP profiles pending Super Admin approval.
-- Also reconciles unsafe profiles that may have been created by older provisioning triggers.

CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  display_name text;
  phone_value text;
  requested_chp_code text;
BEGIN
  display_name := coalesce(
    nullif(trim(coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', '')), ''),
    split_part(new.email, '@', 1),
    new.email
  );

  phone_value := nullif(trim(coalesce(new.raw_user_meta_data->>'phone', new.phone, '')), '');
  requested_chp_code := nullif(trim(coalesce(new.raw_user_meta_data->>'chp_code_requested', new.raw_user_meta_data->>'chp_code', '')), '');

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
  VALUES (
    new.id,
    null,
    'chp'::app_role,
    display_name,
    new.email,
    phone_value,
    false,
    'pending'::user_approval_status,
    requested_chp_code
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = coalesce(nullif(trim(public.users.full_name), ''), excluded.full_name),
    email = excluded.email,
    phone = coalesce(public.users.phone, excluded.phone),
    chp_code_requested = coalesce(public.users.chp_code_requested, excluded.chp_code_requested),
    updated_at = now()
  WHERE public.users.approval_status = 'pending'::user_approval_status;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

WITH unsafe_pending AS (
  SELECT id, role, facility_id, active
  FROM public.users
  WHERE approval_status = 'pending'::user_approval_status
    AND (role::text <> 'chp' OR active = true OR facility_id IS NOT NULL)
), repaired AS (
  UPDATE public.users u
  SET role = 'chp'::app_role,
      facility_id = null,
      active = false,
      updated_at = now()
  FROM unsafe_pending up
  WHERE u.id = up.id
  RETURNING u.id, up.role AS old_role, up.facility_id AS old_facility_id, up.active AS old_active,
            u.role AS new_role, u.facility_id AS new_facility_id, u.active AS new_active
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
  id,
  'change_role',
  jsonb_build_object('role', old_role, 'facility_id', old_facility_id, 'active', old_active, 'approval_status', 'pending'),
  jsonb_build_object('role', new_role, 'facility_id', new_facility_id, 'active', new_active, 'approval_status', 'pending'),
  'Registration hardening: pending self-registered users must remain CHP, inactive, and unassigned until Super Admin approval.'
FROM repaired;
