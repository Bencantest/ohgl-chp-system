-- 006_policies.sql
-- Enables RLS security policies on new tables and allocates execution grants

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

-- Enable RLS on referral_status_events
ALTER TABLE referral_status_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS events_select ON referral_status_events;
CREATE POLICY events_select ON referral_status_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM referrals r 
      WHERE r.id = referral_id 
        AND public.same_facility(r.facility_id)
        AND (public.has_permission('referral:read') OR (public.has_permission('referral:read_own') AND r.created_by = auth.uid()))
    )
  );

-- Allocate Grants
GRANT SELECT ON referrals_secure TO authenticated;
GRANT SELECT ON chp_directory_secure TO authenticated;
GRANT SELECT, UPDATE, INSERT ON notifications TO authenticated;
GRANT SELECT, INSERT ON referral_status_events TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_chp_secure(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION update_referral_secure_legacy(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_referral_secure_full(uuid, jsonb) TO authenticated;
