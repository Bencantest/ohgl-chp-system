-- 20260705_000017_security_hardening_search_path.sql
-- OCHP-003D Security Hardening: ensure legacy SECURITY DEFINER trigger
-- functions have an explicit search_path. No business logic changes.

ALTER FUNCTION public.populate_audit_metadata()
  SET search_path = public;

ALTER FUNCTION public.audit_referral_status_change()
  SET search_path = public;
