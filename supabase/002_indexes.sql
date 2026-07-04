-- 002_indexes.sql
-- Optimizes notifications, referrals, and status audit querying

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created ON notifications(user_id, created_at desc);
CREATE INDEX IF NOT EXISTS idx_notifications_facility_created ON notifications(facility_id, created_at desc) WHERE user_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_referral_events_referral_created ON referral_status_events(referral_id, changed_at);
