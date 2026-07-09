-- rollback_004_functions.sql
-- Restores role permission helpers and original single-field RPC functions

-- 1. Drop newer functions
DROP FUNCTION IF EXISTS update_referral_secure_full(uuid, jsonb) CASCADE;
DROP FUNCTION IF EXISTS update_referral_secure_legacy(uuid, text, text) CASCADE;

-- 2. Restore original role permissions function
CREATE OR REPLACE FUNCTION role_permissions(p_role text)
RETURNS text[]
LANGUAGE sql
STABLE
IMMUTABLE
AS $$
  SELECT CASE p_role
    WHEN 'super_admin' THEN ARRAY['*']::text[]
    WHEN 'facility_admin' THEN ARRAY['facility:manage','facility:read','patient:read','patient:write','referral:create','referral:read','referral:update','referral:delete','chp:read','chp:create','chp:update','chp:delete','report:read','group:read','audit:read']::text[]
    WHEN 'facility_officer' THEN ARRAY['facility:read','patient:read','referral:create','referral:read','referral:update','report:read']::text[]
    WHEN 'clinician' THEN ARRAY['facility:read','patient:read','referral:create','referral:read','referral:update','report:read']::text[]
    WHEN 'chp' THEN ARRAY['facility:read','referral:create','referral:read_own']::text[]
    WHEN 'viewer' THEN ARRAY['facility:read','referral:create','referral:read_own']::text[]
    ELSE ARRAY[]::text[]
  END
$$;

-- Restore original role normalization
CREATE OR REPLACE FUNCTION normalized_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT CASE current_user_role()::text
    WHEN 'clinician' THEN 'facility_officer'
    WHEN 'viewer' THEN 'chp'
    ELSE current_user_role()::text
  END
$$;

-- Restore original single-field update_referral_secure function
CREATE OR REPLACE FUNCTION update_referral_secure(p_referral_id uuid, p_field text, p_value text)
RETURNS referrals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec referrals;
  actor_name text;
  next_status referral_workflow_status;
BEGIN
  IF NOT public.has_permission('referral:update') THEN
    RAISE EXCEPTION 'Only Facility Officers can update referrals.';
  END IF;

  SELECT * INTO rec FROM referrals WHERE id = p_referral_id AND public.same_facility(facility_id);
  IF rec.id IS NULL THEN
    RAISE EXCEPTION 'Referral not found.';
  END IF;

  IF p_field = 'workflow_status' THEN
    next_status := p_value::referral_workflow_status;
    UPDATE referrals SET workflow_status = next_status, updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
    SELECT full_name INTO actor_name FROM users WHERE id = auth.uid();
    INSERT INTO referral_status_events(referral_id, status, responsible_user_id, responsible_user_name)
    VALUES (p_referral_id, next_status, auth.uid(), actor_name);
  ELSIF p_field = 'received_by' THEN
    UPDATE referrals SET received_by = p_value, updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
  ELSIF p_field = 'file_no' THEN
    UPDATE referrals SET file_no = p_value, updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
  ELSIF p_field = 'sha_no' THEN
    UPDATE referrals SET sha_no_ciphertext = pgp_sym_encrypt(coalesce(p_value, ''), current_setting('app.encryption_key', true)), updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
  ELSIF p_field = 'clinical_notes' OR p_field = 'notes' THEN
    UPDATE referrals SET clinical_notes_ciphertext = pgp_sym_encrypt(coalesce(p_value, ''), current_setting('app.encryption_key', true)), updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
  ELSE
    RAISE EXCEPTION 'Field % cannot be updated through referral workflow.', p_field;
  END IF;
  RETURN rec;
END; $$;
