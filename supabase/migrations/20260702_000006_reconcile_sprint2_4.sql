-- Idempotent Reconciliation Migration
-- Reconciles database objects for Sprints 2-4 and deploys modern update RPCs

-- 1. Enum modifications
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Submitted';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Under Review';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Received';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'In Consultation';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Admitted';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Completed';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Closed';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Cancelled';

-- 2. Alter Base Tables
ALTER TABLE patients ADD COLUMN IF NOT EXISTS county text;
ALTER TABLE patients ADD COLUMN IF NOT EXISTS subcounty text;
ALTER TABLE patients ADD COLUMN IF NOT EXISTS village text;

ALTER TABLE referrals ADD COLUMN IF NOT EXISTS national_id text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS county text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS subcounty text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS village text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS referral_reason text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS referral_facility_id uuid REFERENCES facilities(id) ON DELETE RESTRICT;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS referral_facility_name text;
ALTER TABLE referrals ADD COLUMN IF NOT EXISTS department text;

-- 3. Create Tables
CREATE TABLE IF NOT EXISTS referral_status_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id uuid NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
  status opd_status NOT NULL,
  old_status opd_status,
  new_status opd_status,
  changed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  responsible_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  responsible_user_name text
);

CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id uuid REFERENCES facilities(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL,
  read boolean NOT NULL DEFAULT false,
  resource_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_select ON notifications;
DROP POLICY IF EXISTS notifications_update ON notifications;
DROP POLICY IF EXISTS notifications_insert ON notifications;

CREATE POLICY notifications_select ON notifications
  FOR SELECT USING (user_id = auth.uid() OR (facility_id = public.current_user_facility() AND user_id IS NULL));

CREATE POLICY notifications_update ON notifications
  FOR UPDATE USING (user_id = auth.uid() OR (facility_id = public.current_user_facility() AND user_id IS NULL))
  WITH CHECK (user_id = auth.uid() OR (facility_id = public.current_user_facility() AND user_id IS NULL));

CREATE POLICY notifications_insert ON notifications
  FOR INSERT WITH CHECK (true);

-- 4. Re-create Views
CREATE OR REPLACE VIEW referrals_secure WITH (security_invoker = true) AS
SELECT
  r.id,
  r.facility_id,
  r.patient_id,
  r.chp_id,
  r.slip_no,
  r.referral_date,
  r.chp_code,
  r.chp_unit,
  pgp_sym_decrypt(r.patient_name_ciphertext, current_setting('app.encryption_key', true)) as patient_name,
  r.national_id,
  r.phone,
  r.age,
  r.sex,
  r.county,
  r.subcounty,
  r.village,
  r.category,
  r.priority,
  r.sha_registered,
  pgp_sym_decrypt(r.presenting_concern_ciphertext, current_setting('app.encryption_key', true)) as presenting_concern,
  r.referral_reason,
  pgp_sym_decrypt(r.clinical_notes_ciphertext, current_setting('app.encryption_key', true)) as clinical_notes,
  r.referral_facility_id,
  r.referral_facility_name,
  r.department,
  r.opd_status as workflow_status, -- compatibility alias
  r.opd_status,
  r.received_by,
  r.file_no,
  pgp_sym_decrypt(r.sha_no_ciphertext, current_setting('app.encryption_key', true)) as sha_no,
  r.created_by,
  creator.full_name as created_by_name,
  r.updated_by,
  updater.full_name as updated_by_name,
  r.created_at,
  r.updated_at,
  coalesce((
    SELECT jsonb_agg(jsonb_build_object('status', e.status, 'at', e.changed_at, 'by', coalesce(e.responsible_user_name, u.full_name)) ORDER BY e.changed_at)
    FROM referral_status_events e
    LEFT JOIN users u ON u.id = e.changed_by
    WHERE e.referral_id = r.id
  ), '[]'::jsonb) as timeline
FROM referrals r
LEFT JOIN users creator ON creator.id = r.created_by
LEFT JOIN users updater ON updater.id = r.updated_by
WHERE public.same_facility(r.facility_id)
  AND (public.has_permission('referral:read') OR (public.has_permission('referral:read_own') AND r.created_by = auth.uid()));

CREATE OR REPLACE VIEW chp_directory_secure WITH (security_invoker = true) AS
SELECT
  c.id,
  c.facility_id,
  c.user_id,
  c.code,
  pgp_sym_decrypt(c.full_name_ciphertext, current_setting('app.encryption_key', true)) as full_name,
  pgp_sym_decrypt(c.national_id_ciphertext, current_setting('app.encryption_key', true)) as national_id,
  pgp_sym_decrypt(c.phone_ciphertext, current_setting('app.encryption_key', true)) as phone,
  c.village,
  c.community_unit,
  c.sha_trained,
  c.jumuisha_enrolled,
  c.active,
  c.notes,
  c.created_at,
  c.updated_at
FROM chp_directory c
WHERE public.same_facility(c.facility_id);

-- 5. Deploy Functions
CREATE OR REPLACE FUNCTION upsert_chp_secure(payload jsonb)
RETURNS chp_directory
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec chp_directory;
  chp_id uuid;
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
    pgp_sym_encrypt(coalesce(payload->>'full_name', ''), current_setting('app.encryption_key', true)),
    pgp_sym_encrypt(coalesce(payload->>'national_id', ''), current_setting('app.encryption_key', true)),
    pgp_sym_encrypt(coalesce(payload->>'phone', ''), current_setting('app.encryption_key', true)),
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

-- Keep and rename legacy RPC
CREATE OR REPLACE FUNCTION update_referral_secure_legacy(p_referral_id uuid, p_field text, p_value text)
RETURNS referrals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec referrals;
  actor_name text;
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

-- Deploy modern update RPC
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

-- 6. Deploy Auditing Triggers
CREATE OR REPLACE FUNCTION audit_referral_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  actor_name text;
BEGIN
  IF (tg_op = 'INSERT') OR (old.opd_status IS DISTINCT FROM new.opd_status) THEN
    SELECT full_name INTO actor_name FROM public.users WHERE id = auth.uid();
    
    INSERT INTO public.referral_status_events (
      referral_id,
      status,
      old_status,
      new_status,
      responsible_user_id,
      responsible_user_name,
      changed_by,
      changed_at
    ) VALUES (
      new.id,
      new.opd_status,
      CASE WHEN tg_op = 'UPDATE' THEN old.opd_status ELSE null END,
      new.opd_status,
      auth.uid(),
      actor_name,
      auth.uid(),
      now()
    );
  END IF;
  RETURN new;
END; $$;

DROP TRIGGER IF EXISTS trg_audit_referral_status_change ON referrals;
CREATE TRIGGER trg_audit_referral_status_change
AFTER INSERT OR UPDATE ON referrals
FOR EACH ROW
EXECUTE FUNCTION audit_referral_status_change();

-- 7. Register Optimizations Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created ON notifications(user_id, created_at desc);
CREATE INDEX IF NOT EXISTS idx_notifications_facility_created ON notifications(facility_id, created_at desc) WHERE user_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_referral_events_referral_created ON referral_status_events(referral_id, changed_at);

-- 8. Grants
GRANT SELECT ON referrals_secure TO authenticated;
GRANT SELECT ON chp_directory_secure TO authenticated;
GRANT SELECT, UPDATE, INSERT ON notifications TO authenticated;
GRANT SELECT, INSERT ON referral_status_events TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_chp_secure(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION update_referral_secure_legacy(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_referral_secure_full(uuid, jsonb) TO authenticated;
