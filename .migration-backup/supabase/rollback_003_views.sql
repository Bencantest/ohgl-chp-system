-- rollback_003_views.sql
-- Restores referrals_secure and chp_directory_secure views to baseline definitions

-- Drop newer versions
DROP VIEW IF EXISTS referrals_secure CASCADE;
DROP VIEW IF EXISTS chp_directory_secure CASCADE;

-- Re-create original referrals_secure view
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
  r.age,
  r.sex,
  r.category,
  r.priority,
  r.sha_registered,
  pgp_sym_decrypt(r.presenting_concern_ciphertext, current_setting('app.encryption_key', true)) as presenting_concern,
  pgp_sym_decrypt(r.clinical_notes_ciphertext, current_setting('app.encryption_key', true)) as clinical_notes,
  r.opd_status,
  r.received_by,
  r.file_no,
  pgp_sym_decrypt(r.sha_no_ciphertext, current_setting('app.encryption_key', true)) as sha_no,
  r.created_by,
  creator.full_name as created_by_name,
  r.updated_by,
  updater.full_name as updated_by_name,
  r.created_at,
  r.updated_at
FROM referrals r
LEFT JOIN users creator ON creator.id = r.created_by
LEFT JOIN users updater ON updater.id = r.updated_by
WHERE public.same_facility(r.facility_id)
  AND (public.has_permission('referral:read') OR (public.has_permission('referral:read_own') AND r.created_by = auth.uid()));
