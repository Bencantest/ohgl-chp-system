-- rollback_002_indexes.sql
-- Drops the indexes created in 002_indexes.sql

DROP INDEX IF EXISTS idx_notifications_recipient_created;
DROP INDEX IF EXISTS idx_notifications_facility_created;
DROP INDEX IF EXISTS idx_referral_events_referral_created;
