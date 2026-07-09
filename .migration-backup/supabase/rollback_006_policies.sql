-- rollback_006_policies.sql
-- Removes RLS policies and revokes permissions introduced in 006_policies.sql

DROP POLICY IF EXISTS notifications_select ON notifications;
DROP POLICY IF EXISTS notifications_update ON notifications;
DROP POLICY IF EXISTS notifications_insert ON notifications;
DROP POLICY IF EXISTS events_select ON referral_status_events;

REVOKE EXECUTE ON FUNCTION update_referral_secure_full(uuid, jsonb) FROM authenticated;
REVOKE EXECUTE ON FUNCTION update_referral_secure_legacy(uuid, text, text) FROM authenticated;
