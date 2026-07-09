-- 001_schema.sql
-- Idempotently creates tables and reconciles enums/columns for Sprints 2-4

-- 1. Extend Enum Types
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Submitted';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Under Review';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Received';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'In Consultation';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Admitted';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Completed';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Closed';
ALTER TYPE opd_status ADD VALUE IF NOT EXISTS 'Cancelled';

ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'facility_manager';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'technician';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'facility_officer';

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
