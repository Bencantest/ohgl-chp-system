-- 20260705_000014_referral_foundation_enhancements.sql
-- OCHP Sprint 2A.1: Referral Foundation Enhancements.
-- Forward-only, additive, and backward compatible with Sprint 2A.

DO $$ BEGIN
  CREATE TYPE referral_assignment_type AS ENUM (
    'assign',
    'reassign',
    'transfer_department',
    'transfer_facility',
    'automatic',
    'emergency_override'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id uuid NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  department_code text NOT NULL,
  department_name text NOT NULL,
  description text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT departments_code_not_blank_chk CHECK (length(trim(department_code)) > 0),
  CONSTRAINT departments_name_not_blank_chk CHECK (length(trim(department_name)) > 0)
);

COMMENT ON TABLE departments IS 'Canonical facility departments for referral routing. The legacy referrals.department text field remains temporarily for backward compatibility.';
COMMENT ON COLUMN referrals.department IS 'Legacy free-text department retained for backward compatibility. TODO: retire after referral workflow uses referrals.department_id and canonical departments.';

ALTER TABLE referrals
  ADD COLUMN IF NOT EXISTS department_id uuid REFERENCES departments(id) ON DELETE SET NULL;

ALTER TABLE referral_events
  ADD COLUMN IF NOT EXISTS event_version integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS event_category text NOT NULL DEFAULT 'workflow',
  ADD COLUMN IF NOT EXISTS event_source text NOT NULL DEFAULT 'ochp',
  ADD COLUMN IF NOT EXISTS correlation_id uuid,
  ADD COLUMN IF NOT EXISTS created_by_system boolean NOT NULL DEFAULT false;

ALTER TABLE referral_clinical_notes
  ADD COLUMN IF NOT EXISTS supersedes_note_id uuid REFERENCES referral_clinical_notes(id) ON DELETE SET NULL;

ALTER TABLE referral_assignment_history
  ADD COLUMN IF NOT EXISTS assignment_type referral_assignment_type NOT NULL DEFAULT 'assign';

ALTER TABLE referral_sla_timers
  ADD COLUMN IF NOT EXISTS paused_by uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS pause_reason text,
  ADD COLUMN IF NOT EXISTS paused_duration interval NOT NULL DEFAULT interval '0 seconds';

UPDATE referral_assignment_history
SET assignment_type = 'assign'::referral_assignment_type
WHERE assignment_type IS NULL;

DO $$ BEGIN
  ALTER TABLE referral_events
    ADD CONSTRAINT referral_events_version_positive_chk CHECK (event_version > 0);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE referral_events
    ADD CONSTRAINT referral_events_category_not_blank_chk CHECK (length(trim(event_category)) > 0);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE referral_events
    ADD CONSTRAINT referral_events_source_not_blank_chk CHECK (length(trim(event_source)) > 0);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE referral_sla_timers
    ADD CONSTRAINT referral_sla_timers_paused_duration_nonnegative_chk CHECK (paused_duration >= interval '0 seconds');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE referral_sla_timers
    ADD CONSTRAINT referral_sla_timers_pause_reason_required_chk CHECK (paused_at IS NULL OR nullif(trim(coalesce(pause_reason, '')), '') IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_departments_facility_code_unique
  ON departments(facility_id, lower(department_code));

CREATE UNIQUE INDEX IF NOT EXISTS idx_departments_facility_name_unique
  ON departments(facility_id, lower(department_name));

CREATE INDEX IF NOT EXISTS idx_departments_facility_active
  ON departments(facility_id, active, department_name);

CREATE INDEX IF NOT EXISTS idx_referrals_department_id_status
  ON referrals(department_id, referral_status, created_at DESC)
  WHERE department_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_events_category_created
  ON referral_events(event_category, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_events_source_created
  ON referral_events(event_source, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_events_correlation
  ON referral_events(correlation_id)
  WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_clinical_notes_supersedes
  ON referral_clinical_notes(supersedes_note_id)
  WHERE supersedes_note_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_assignment_history_type_created
  ON referral_assignment_history(assignment_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_sla_timers_paused_by
  ON referral_sla_timers(paused_by, paused_at DESC)
  WHERE paused_by IS NOT NULL;
