-- rollback_005_triggers.sql
-- Reverts status change triggers on the referrals table

DROP TRIGGER IF EXISTS trg_audit_referral_status_change ON referrals;
DROP FUNCTION IF EXISTS audit_referral_status_change() CASCADE;
