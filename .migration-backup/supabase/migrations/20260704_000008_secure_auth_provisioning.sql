-- 20260704_000008_secure_auth_provisioning.sql
-- OCHP Sprint 1 Task 2: secure auth provisioning.
-- Forward-only correction: legacy inactive users are suspended, not deactivated.

WITH corrected AS (
  UPDATE users
  SET approval_status = 'suspended'::user_approval_status,
      updated_at = now()
  WHERE active = false
    AND approval_status = 'deactivated'
  RETURNING id
)
INSERT INTO user_access_audit (
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
  'suspend',
  jsonb_build_object('approval_status', 'deactivated'),
  jsonb_build_object('approval_status', 'suspended'),
  'Forward lifecycle correction: legacy inactive users are suspended unless explicitly deactivated by Super Admin.'
FROM corrected;

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
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

