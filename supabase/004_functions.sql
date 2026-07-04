-- 004_functions.sql
-- Deploys helper functions, RBAC mapping rules, and secure data modification RPCs

-- Enforces RBAC permissions list including new roles
CREATE OR REPLACE FUNCTION role_permissions(p_role text)
RETURNS text[]
LANGUAGE sql
STABLE
IMMUTABLE
AS $$
  SELECT CASE p_role
    WHEN 'super_admin' THEN ARRAY['*']::text[]
    WHEN 'facility_manager' THEN ARRAY['facility:manage','facility:read','patient:read','patient:write','referral:create','referral:read','referral:update','referral:delete','chp:read','chp:create','chp:update','chp:delete','report:read','group:read']::text[]
    WHEN 'facility_admin' THEN ARRAY['facility:manage','facility:read','patient:read','patient:write','referral:create','referral:read','referral:update','referral:delete','chp:read','chp:create','chp:update','chp:delete','report:read','group:read']::text[]
    WHEN 'facility_officer' THEN ARRAY['facility:read','patient:read','referral:create','referral:read','referral:update','report:read']::text[]
    WHEN 'clinician' THEN ARRAY['facility:read','patient:read','referral:create','referral:read','referral:update','report:read']::text[]
    WHEN 'technician' THEN ARRAY['facility:read','patient:read','referral:create','referral:read','referral:update','report:read']::text[]
    WHEN 'chp' THEN ARRAY['facility:read','referral:create','referral:read_own']::text[]
    WHEN 'viewer' THEN ARRAY['facility:read','referral:create','referral:read_own']::text[]
    ELSE ARRAY[]::text[]
  END
$$;

-- Standardizes role normalization
CREATE OR REPLACE FUNCTION normalized_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT CASE current_user_role()::text
    WHEN 'clinician' THEN 'facility_officer'
    WHEN 'technician' THEN 'facility_officer'
    WHEN 'viewer' THEN 'chp'
    WHEN 'facility_admin' THEN 'facility_manager'
    ELSE current_user_role()::text
  END
$$;

-- Secure CHP Directory Upsert RPC
CREATE OR REPLACE FUNCTION upsert_chp_secure(payload jsonb)
RETURNS chp_directory
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec chp_directory;
  chp_id uuid;
KeepKey text := current_setting('app.encryption_key', true);
BEGIN
  IF NOT public.has_permission('chp:create') AND NOT public.has_permission('facility:manage') THEN
    RAISE EXCEPTION 'You do not have permission to manage CHPs.';
  END IF;

  IF payload->>'id' IS NOT NULL THEN
    chp_id := (payload->>'id')::uuid;
  ELSE
    SELECT id INTO chp_id FROM chp_directory WHERE facility_id = (payload->>'facility_id')::uuid AND code = payload->>'code';
    IF chp_id IS NULL THEN
      chp_id := gen_random_uuid();
    END IF;
  END IF;

  INSERT INTO chp_directory (
    id, facility_id, user_id, code,
    full_name_ciphertext, national_id_ciphertext, phone_ciphertext,
    village, community_unit, sha_trained, jumuisha_enrolled, active, notes, updated_at
  ) VALUES (
    chp_id,
    (payload->>'facility_id')::uuid,
    (payload->>'user_id')::uuid,
    payload->>'code',
    pgp_sym_encrypt(coalesce(payload->>'full_name', ''), KeepKey),
    pgp_sym_encrypt(coalesce(payload->>'national_id', ''), KeepKey),
    pgp_sym_encrypt(coalesce(payload->>'phone', ''), KeepKey),
    payload->>'village',
    payload->>'community_unit',
    coalesce((payload->>'sha_trained')::boolean, false),
    coalesce((payload->>'jumuisha_enrolled')::boolean, false),
    coalesce((payload->>'active')::boolean, true),
    payload->>'notes',
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    facility_id = excluded.facility_id,
    user_id = excluded.user_id,
    code = excluded.code,
    full_name_ciphertext = excluded.full_name_ciphertext,
    national_id_ciphertext = excluded.national_id_ciphertext,
    phone_ciphertext = excluded.phone_ciphertext,
    village = excluded.village,
    community_unit = excluded.community_unit,
    sha_trained = excluded.sha_trained,
    jumuisha_enrolled = excluded.jumuisha_enrolled,
    active = excluded.active,
    notes = excluded.notes,
    updated_at = now()
  RETURNING * INTO rec;

  RETURN rec;
END; $$;

-- Standard single-field update wrapper (re-mapped to update opd_status)
CREATE OR REPLACE FUNCTION update_referral_secure_legacy(p_referral_id uuid, p_field text, p_value text)
RETURNS referrals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec referrals;
BEGIN
  IF NOT public.has_permission('referral:update') THEN
    RAISE EXCEPTION 'You do not have permission to update referrals.';
  END IF;

  SELECT * INTO rec FROM referrals WHERE id = p_referral_id AND public.same_facility(facility_id);
  IF rec.id IS NULL THEN
    RAISE EXCEPTION 'Referral not found.';
  END IF;

  IF p_field = 'workflow_status' OR p_field = 'opd_status' THEN
    UPDATE referrals SET opd_status = p_value::opd_status, updated_by = auth.uid(), updated_at = now() WHERE id = p_referral_id RETURNING * INTO rec;
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

-- Modern atomic update RPC supporting partial updates
CREATE OR REPLACE FUNCTION update_referral_secure_full(p_referral_id uuid, payload jsonb)
RETURNS referrals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec referrals;
  encrypt_key text;
BEGIN
  IF NOT public.has_permission('referral:update') THEN
    RAISE EXCEPTION 'You do not have permission to update referrals.';
  END IF;

  encrypt_key := current_setting('app.encryption_key', true);

  SELECT * INTO rec FROM referrals WHERE id = p_referral_id AND public.same_facility(facility_id);
  IF rec.id IS NULL THEN
    RAISE EXCEPTION 'Referral not found or access denied.';
  END IF;

  IF jsonb_exists(payload, 'referral_date') THEN
    rec.referral_date := (payload->>'referral_date')::date;
  END IF;
  IF jsonb_exists(payload, 'patient_name') THEN
    rec.patient_name_ciphertext := pgp_sym_encrypt(coalesce(payload->>'patient_name', ''), encrypt_key);
  END IF;
  IF jsonb_exists(payload, 'national_id') THEN
    rec.national_id := payload->>'national_id';
  END IF;
  IF jsonb_exists(payload, 'phone') THEN
    rec.phone := payload->>'phone';
  END if;
  IF jsonb_exists(payload, 'age') THEN
    rec.age := nullif(payload->>'age', '')::int;
  END IF;
  IF jsonb_exists(payload, 'sex') THEN
    rec.sex := nullif(payload->>'sex', '');
  END IF;
  IF jsonb_exists(payload, 'county') THEN
    rec.county := payload->>'county';
  END IF;
  IF jsonb_exists(payload, 'subcounty') THEN
    rec.subcounty := payload->>'subcounty';
  END IF;
  IF jsonb_exists(payload, 'village') THEN
    rec.village := payload->>'village';
  END IF;
  IF jsonb_exists(payload, 'priority') THEN
    rec.priority := (payload->>'priority')::referral_priority;
  END IF;
  IF jsonb_exists(payload, 'sha_registered') THEN
    rec.sha_registered := (payload->>'sha_registered')::boolean;
  END IF;
  IF jsonb_exists(payload, 'presenting_concern') THEN
    rec.presenting_concern_ciphertext := pgp_sym_encrypt(coalesce(payload->>'presenting_concern', ''), encrypt_key);
  END IF;
  IF jsonb_exists(payload, 'referral_reason') THEN
    rec.referral_reason := payload->>'referral_reason';
  END IF;
  IF jsonb_exists(payload, 'clinical_notes') THEN
    rec.clinical_notes_ciphertext := pgp_sym_encrypt(coalesce(payload->>'clinical_notes', ''), encrypt_key);
  END IF;
  IF jsonb_exists(payload, 'referral_facility_id') THEN
    rec.referral_facility_id := (payload->>'referral_facility_id')::uuid;
  END IF;
  IF jsonb_exists(payload, 'referral_facility_name') THEN
    rec.referral_facility_name := payload->>'referral_facility_name';
  END IF;
  IF jsonb_exists(payload, 'department') THEN
    rec.department := payload->>'department';
    rec.category := ARRAY[payload->>'department'];
  END IF;
  IF jsonb_exists(payload, 'received_by') THEN
    rec.received_by := payload->>'received_by';
  END IF;
  IF jsonb_exists(payload, 'file_no') THEN
    rec.file_no := payload->>'file_no';
  END IF;
  IF jsonb_exists(payload, 'sha_no') THEN
    rec.sha_no_ciphertext := pgp_sym_encrypt(coalesce(payload->>'sha_no', ''), encrypt_key);
  END IF;
  IF jsonb_exists(payload, 'opd_status') THEN
    rec.opd_status := (payload->>'opd_status')::opd_status;
  END IF;

  UPDATE referrals
  SET
    referral_date = rec.referral_date,
    patient_name_ciphertext = rec.patient_name_ciphertext,
    national_id = rec.national_id,
    phone = rec.phone,
    age = rec.age,
    sex = rec.sex,
    county = rec.county,
    subcounty = rec.subcounty,
    village = rec.village,
    priority = rec.priority,
    sha_registered = rec.sha_registered,
    presenting_concern_ciphertext = rec.presenting_concern_ciphertext,
    referral_reason = rec.referral_reason,
    clinical_notes_ciphertext = rec.clinical_notes_ciphertext,
    referral_facility_id = rec.referral_facility_id,
    referral_facility_name = rec.referral_facility_name,
    department = rec.department,
    category = rec.category,
    opd_status = rec.opd_status,
    received_by = rec.received_by,
    file_no = rec.file_no,
    sha_no_ciphertext = rec.sha_no_ciphertext,
    updated_by = auth.uid(),
    updated_at = now()
  WHERE id = p_referral_id
  RETURNING * INTO rec;

  RETURN rec;
END; $$;
