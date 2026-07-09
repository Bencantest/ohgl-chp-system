-- 003_views.sql
-- Deploys secure views that handle PHI decryption for authorized users

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
