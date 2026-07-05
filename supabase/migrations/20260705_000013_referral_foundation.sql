-- 20260705_000013_referral_foundation.sql
-- OCHP-002A Referral Foundation: canonical status, stage, outcome, ownership,
-- assignment history, events, clinical notes, and SLA schema.
-- Forward-only and backward compatible with existing referral workflows.

DO $$ BEGIN
  CREATE TYPE referral_canonical_status AS ENUM (
    'draft',
    'submitted',
    'accepted',
    'received',
    'assigned',
    'triaged',
    'in_consultation',
    'treatment',
    'outcome_recorded',
    'completed',
    'closed',
    'cancelled',
    'reopened',
    'archived'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE referral_stage AS ENUM (
    'registration',
    'receiving',
    'clinical',
    'treatment',
    'outcome',
    'follow_up',
    'closure',
    'archive'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE referral_outcome AS ENUM (
    'treated',
    'admitted',
    'transferred',
    'follow_up_required',
    'referred_higher',
    'deceased',
    'resolved',
    'unknown'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE referral_owner_type AS ENUM (
    'chp',
    'facility',
    'department',
    'assigned_user'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE referral_note_type AS ENUM (
    'chp',
    'receiving',
    'triage',
    'consultation',
    'investigation',
    'treatment',
    'outcome',
    'follow_up'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE referrals
  ADD COLUMN IF NOT EXISTS referral_status referral_canonical_status NOT NULL DEFAULT 'submitted',
  ADD COLUMN IF NOT EXISTS referral_stage referral_stage NOT NULL DEFAULT 'registration',
  ADD COLUMN IF NOT EXISTS referral_outcome referral_outcome NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS current_owner_type referral_owner_type NOT NULL DEFAULT 'facility',
  ADD COLUMN IF NOT EXISTS current_owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS current_owner_facility_id uuid REFERENCES facilities(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS current_owner_department text,
  ADD COLUMN IF NOT EXISTS ownership_updated_at timestamptz NOT NULL DEFAULT now();

UPDATE referrals
SET referral_status = CASE
    WHEN opd_status::text IN ('Pending', 'Submitted') THEN 'submitted'::referral_canonical_status
    WHEN opd_status::text = 'Received' THEN 'received'::referral_canonical_status
    WHEN opd_status::text = 'Under Review' THEN 'triaged'::referral_canonical_status
    WHEN opd_status::text = 'In Consultation' THEN 'in_consultation'::referral_canonical_status
    WHEN opd_status::text = 'Admitted' THEN 'treatment'::referral_canonical_status
    WHEN opd_status::text IN ('Completed', 'Attended') THEN 'completed'::referral_canonical_status
    WHEN opd_status::text = 'Closed' THEN 'closed'::referral_canonical_status
    WHEN opd_status::text IN ('Cancelled', 'DNA') THEN 'cancelled'::referral_canonical_status
    ELSE referral_status
  END,
  referral_outcome = CASE
    WHEN opd_status::text IN ('Completed', 'Attended') THEN 'treated'::referral_outcome
    WHEN opd_status::text = 'Admitted' THEN 'admitted'::referral_outcome
    ELSE referral_outcome
  END,
  current_owner_facility_id = coalesce(current_owner_facility_id, facility_id),
  current_owner_user_id = coalesce(current_owner_user_id, updated_by, created_by),
  current_owner_department = coalesce(current_owner_department, department),
  current_owner_type = CASE
    WHEN updated_by IS NOT NULL THEN 'assigned_user'::referral_owner_type
    WHEN department IS NOT NULL THEN 'department'::referral_owner_type
    ELSE 'facility'::referral_owner_type
  END,
  ownership_updated_at = coalesce(ownership_updated_at, updated_at, created_at, now())
WHERE referral_status = 'submitted'::referral_canonical_status
  AND referral_stage = 'registration'::referral_stage
  AND referral_outcome = 'unknown'::referral_outcome;

UPDATE referrals
SET referral_stage = CASE referral_status
    WHEN 'draft' THEN 'registration'::referral_stage
    WHEN 'submitted' THEN 'registration'::referral_stage
    WHEN 'accepted' THEN 'receiving'::referral_stage
    WHEN 'received' THEN 'receiving'::referral_stage
    WHEN 'assigned' THEN 'clinical'::referral_stage
    WHEN 'triaged' THEN 'clinical'::referral_stage
    WHEN 'in_consultation' THEN 'clinical'::referral_stage
    WHEN 'treatment' THEN 'treatment'::referral_stage
    WHEN 'outcome_recorded' THEN 'outcome'::referral_stage
    WHEN 'completed' THEN 'closure'::referral_stage
    WHEN 'closed' THEN 'closure'::referral_stage
    WHEN 'cancelled' THEN 'closure'::referral_stage
    WHEN 'reopened' THEN 'receiving'::referral_stage
    WHEN 'archived' THEN 'archive'::referral_stage
    ELSE referral_stage
  END
WHERE referral_stage = 'registration'::referral_stage
  AND referral_status <> 'submitted'::referral_canonical_status;

CREATE TABLE IF NOT EXISTS referral_assignment_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id uuid NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
  previous_owner_type referral_owner_type,
  previous_owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  previous_owner_facility_id uuid REFERENCES facilities(id) ON DELETE SET NULL,
  previous_department text,
  new_owner_type referral_owner_type NOT NULL,
  new_owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  new_owner_facility_id uuid REFERENCES facilities(id) ON DELETE SET NULL,
  new_department text,
  actor_id uuid REFERENCES users(id) ON DELETE SET NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS referral_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id uuid NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
  event_name text NOT NULL,
  actor_id uuid REFERENCES users(id) ON DELETE SET NULL,
  actor_role app_role,
  previous_status referral_canonical_status,
  new_status referral_canonical_status,
  previous_stage referral_stage,
  new_stage referral_stage,
  owner_type referral_owner_type,
  owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  owner_facility_id uuid REFERENCES facilities(id) ON DELETE SET NULL,
  department text,
  facility_id uuid REFERENCES facilities(id) ON DELETE SET NULL,
  reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT referral_events_name_not_blank_chk CHECK (length(trim(event_name)) > 0)
);

CREATE TABLE IF NOT EXISTS referral_clinical_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id uuid NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
  note_type referral_note_type NOT NULL,
  note_text text NOT NULL,
  author_id uuid REFERENCES users(id) ON DELETE SET NULL,
  author_role app_role,
  version integer NOT NULL DEFAULT 1,
  previous_note_id uuid REFERENCES referral_clinical_notes(id) ON DELETE SET NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT referral_clinical_notes_version_chk CHECK (version > 0),
  CONSTRAINT referral_clinical_notes_text_not_blank_chk CHECK (length(trim(note_text)) > 0)
);

CREATE TABLE IF NOT EXISTS referral_sla_timers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_id uuid NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
  transition_name text NOT NULL,
  target_at timestamptz NOT NULL,
  warning_at timestamptz NOT NULL,
  breach_at timestamptz NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  paused_at timestamptz,
  resumed_at timestamptz,
  completed_at timestamptz,
  breached boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT referral_sla_timers_transition_not_blank_chk CHECK (length(trim(transition_name)) > 0),
  CONSTRAINT referral_sla_timers_threshold_order_chk CHECK (warning_at <= breach_at AND target_at <= breach_at)
);

DO $$ BEGIN
  ALTER TABLE referrals
    ADD CONSTRAINT referrals_current_owner_required_chk
    CHECK (
      (current_owner_type = 'chp' AND current_owner_user_id IS NOT NULL)
      OR (current_owner_type = 'facility' AND current_owner_facility_id IS NOT NULL)
      OR (current_owner_type = 'department' AND current_owner_facility_id IS NOT NULL AND current_owner_department IS NOT NULL)
      OR (current_owner_type = 'assigned_user' AND current_owner_user_id IS NOT NULL)
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


CREATE INDEX IF NOT EXISTS idx_referrals_canonical_status_stage
  ON referrals(referral_status, referral_stage, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referrals_current_owner_user
  ON referrals(current_owner_user_id, referral_status, created_at DESC)
  WHERE current_owner_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referrals_current_owner_facility
  ON referrals(current_owner_facility_id, referral_status, created_at DESC)
  WHERE current_owner_facility_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referrals_current_department
  ON referrals(current_owner_facility_id, current_owner_department, referral_status)
  WHERE current_owner_department IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_assignment_history_referral_created
  ON referral_assignment_history(referral_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_assignment_history_new_owner
  ON referral_assignment_history(new_owner_user_id, created_at DESC)
  WHERE new_owner_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_events_referral_created
  ON referral_events(referral_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_events_name_created
  ON referral_events(event_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_events_facility_created
  ON referral_events(facility_id, created_at DESC)
  WHERE facility_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_referral_clinical_notes_referral_type_created
  ON referral_clinical_notes(referral_id, note_type, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_referral_clinical_notes_version_unique
  ON referral_clinical_notes(referral_id, note_type, version);

CREATE INDEX IF NOT EXISTS idx_referral_sla_timers_referral_transition
  ON referral_sla_timers(referral_id, transition_name, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_referral_sla_timers_breach_queue
  ON referral_sla_timers(breached, breach_at)
  WHERE completed_at IS NULL;



