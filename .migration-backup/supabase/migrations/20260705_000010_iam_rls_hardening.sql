-- 20260705_000010_iam_rls_hardening.sql
-- OCHP Sprint 1 Task 5: IAM RLS hardening.

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_access_audit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select ON users;
DROP POLICY IF EXISTS users_admin_write ON users;
DROP POLICY IF EXISTS users_no_direct_insert ON users;
DROP POLICY IF EXISTS users_no_direct_update ON users;
DROP POLICY IF EXISTS users_no_direct_delete ON users;

CREATE POLICY users_select ON users
  FOR SELECT
  USING (public.is_super_admin() OR id = auth.uid());

CREATE POLICY users_no_direct_insert ON users
  FOR INSERT
  WITH CHECK (false);

CREATE POLICY users_no_direct_update ON users
  FOR UPDATE
  USING (false)
  WITH CHECK (false);

CREATE POLICY users_no_direct_delete ON users
  FOR DELETE
  USING (false);

DROP POLICY IF EXISTS permissions_select ON permissions;
DROP POLICY IF EXISTS permissions_no_direct_write ON permissions;
DROP POLICY IF EXISTS role_permissions_select ON role_permissions;
DROP POLICY IF EXISTS role_permissions_no_direct_write ON role_permissions;

CREATE POLICY permissions_select ON permissions
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY permissions_no_direct_write ON permissions
  FOR ALL
  USING (false)
  WITH CHECK (false);

CREATE POLICY role_permissions_select ON role_permissions
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY role_permissions_no_direct_write ON role_permissions
  FOR ALL
  USING (false)
  WITH CHECK (false);

DROP POLICY IF EXISTS user_access_audit_select ON user_access_audit;
DROP POLICY IF EXISTS user_access_audit_no_direct_insert ON user_access_audit;
DROP POLICY IF EXISTS user_access_audit_no_direct_update ON user_access_audit;
DROP POLICY IF EXISTS user_access_audit_no_direct_delete ON user_access_audit;

CREATE POLICY user_access_audit_select ON user_access_audit
  FOR SELECT
  USING (public.is_super_admin());

CREATE POLICY user_access_audit_no_direct_insert ON user_access_audit
  FOR INSERT
  WITH CHECK (false);

CREATE POLICY user_access_audit_no_direct_update ON user_access_audit
  FOR UPDATE
  USING (false)
  WITH CHECK (false);

CREATE POLICY user_access_audit_no_direct_delete ON user_access_audit
  FOR DELETE
  USING (false);

GRANT SELECT ON permissions TO authenticated;
GRANT SELECT ON role_permissions TO authenticated;
GRANT SELECT ON user_access_audit TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON users FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON permissions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON role_permissions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON user_access_audit FROM authenticated;
