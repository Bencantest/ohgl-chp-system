-- 005_triggers.sql
-- Deploys triggers for automatic logging of status updates to referral_status_events

CREATE OR REPLACE FUNCTION audit_referral_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  actor_name text;
BEGIN
  IF (tg_op = 'INSERT') OR (old.opd_status IS DISTINCT FROM new.opd_status) THEN
    SELECT full_name INTO actor_name FROM public.users WHERE id = auth.uid();
    
    INSERT INTO public.referral_status_events (
      referral_id,
      status,
      old_status,
      new_status,
      responsible_user_id,
      responsible_user_name,
      changed_by,
      changed_at
    ) VALUES (
      new.id,
      new.opd_status,
      CASE WHEN tg_op = 'UPDATE' THEN old.opd_status ELSE null END,
      new.opd_status,
      auth.uid(),
      actor_name,
      auth.uid(),
      now()
    );
  END IF;
  RETURN new;
END; $$;

DROP TRIGGER IF EXISTS trg_audit_referral_status_change ON referrals;
CREATE TRIGGER trg_audit_referral_status_change
AFTER INSERT OR UPDATE ON referrals
FOR EACH ROW
EXECUTE FUNCTION audit_referral_status_change();
