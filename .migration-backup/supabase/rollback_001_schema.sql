-- rollback_001_schema.sql
-- Reverts tables and base column additions introduced in 001_schema.sql

-- 1. Drop Tables
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS referral_status_events CASCADE;

-- 2. Drop Added Columns from Base Tables
ALTER TABLE patients DROP COLUMN IF EXISTS county;
ALTER TABLE patients DROP COLUMN IF EXISTS subcounty;
ALTER TABLE patients DROP COLUMN IF EXISTS village;

ALTER TABLE referrals DROP COLUMN IF EXISTS national_id;
ALTER TABLE referrals DROP COLUMN IF EXISTS phone;
ALTER TABLE referrals DROP COLUMN IF EXISTS county;
ALTER TABLE referrals DROP COLUMN IF EXISTS subcounty;
ALTER TABLE referrals DROP COLUMN IF EXISTS village;
ALTER TABLE referrals DROP COLUMN IF EXISTS referral_reason;
ALTER TABLE referrals DROP COLUMN IF EXISTS referral_facility_id;
ALTER TABLE referrals DROP COLUMN IF EXISTS referral_facility_name;
ALTER TABLE referrals DROP COLUMN IF EXISTS department;

-- Note: PostgreSQL does not natively support dropping enum values (e.g. ALTER TYPE DROP VALUE).
-- The added enum values in opd_status and app_role will remain in the system to prevent data loss,
-- but will not be referenced by the application code.
