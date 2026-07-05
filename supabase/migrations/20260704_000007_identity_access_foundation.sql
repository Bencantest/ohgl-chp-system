-- 20260704_000007_identity_access_foundation.sql
-- OCHP Sprint 1 Task 1: Identity & Access database foundation.
-- Non-destructive: adds lifecycle, canonical permission tables, and access audit.

DO $$ BEGIN
  CREATE TYPE user_approval_status AS ENUM (
    'pending',
    'approved',
    'suspended',
    'rejected',
    'deactivated'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'facility_manager';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'facility_officer';

ALTER TABLE users
  ALTER COLUMN role SET DEFAULT 'chp';

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS approval_status user_approval_status NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS chp_code_requested text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

UPDATE users
SET role = CASE role::text
  WHEN 'facility_admin' THEN 'facility_manager'::app_role
  WHEN 'technician' THEN 'facility_officer'::app_role
  WHEN 'viewer' THEN 'chp'::app_role
  ELSE role
END
WHERE role::text IN ('facility_admin', 'technician', 'viewer');

UPDATE users
SET approval_status = CASE
  WHEN active = false THEN 'deactivated'::user_approval_status
  ELSE 'approved'::user_approval_status
END
WHERE approval_status = 'pending'
  AND created_at < now();

DO $$ BEGIN
  ALTER TABLE users
    ADD CONSTRAINT users_role_canonical_chk
    CHECK (role::text IN ('super_admin', 'facility_manager', 'facility_officer', 'clinician', 'chp'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS permissions (
  key text PRIMARY KEY,
  description text NOT NULL,
  permission_group text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  id bigserial PRIMARY KEY,
  role app_role NOT NULL,
  permission text NOT NULL REFERENCES permissions(key) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_access_audit (
  id bigserial PRIMARY KEY,
  actor_id uuid REFERENCES users(id) ON DELETE SET NULL,
  target_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action text NOT NULL CHECK (action IN (
    'approve',
    'reject',
    'suspend',
    'reactivate',
    'deactivate',
    'assign_facility',
    'change_role'
  )),
  old_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  new_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO permissions (key, description, permission_group) VALUES
  ('user:read', 'Read user profiles and approval queues', 'user'),
  ('user:approve', 'Approve pending users', 'user'),
  ('user:reject', 'Reject pending users', 'user'),
  ('user:suspend', 'Suspend active users', 'user'),
  ('user:reactivate', 'Reactivate suspended users', 'user'),
  ('user:deactivate', 'Deactivate users', 'user'),
  ('user:assign_facility', 'Assign users to facilities', 'user'),
  ('user:change_role', 'Change user roles', 'user'),
  ('facility:read', 'Read facility information', 'facility'),
  ('facility:manage', 'Manage facility information', 'facility'),
  ('referral:create', 'Create referrals', 'referral'),
  ('referral:read_own', 'Read own referrals', 'referral'),
  ('referral:read_facility', 'Read facility referrals', 'referral'),
  ('referral:update_facility', 'Update facility referral workflow fields', 'referral'),
  ('referral:complete', 'Complete clinical referral workflow', 'referral'),
  ('report:read_facility', 'Read facility reports', 'report'),
  ('report:read_system', 'Read system-wide reports', 'report'),
  ('report:export', 'Export reports', 'report'),
  ('audit:read', 'Read audit events', 'audit'),
  ('audit:export', 'Export audit events', 'audit'),
  ('settings:manage_facility', 'Manage facility settings', 'settings'),
  ('settings:manage_system', 'Manage system settings', 'settings')
ON CONFLICT (key) DO UPDATE SET
  description = excluded.description,
  permission_group = excluded.permission_group;

INSERT INTO role_permissions (role, permission) SELECT v.role::app_role, v.permission FROM (VALUES
  ('super_admin', 'user:read'),
  ('super_admin', 'user:approve'),
  ('super_admin', 'user:reject'),
  ('super_admin', 'user:suspend'),
  ('super_admin', 'user:reactivate'),
  ('super_admin', 'user:deactivate'),
  ('super_admin', 'user:assign_facility'),
  ('super_admin', 'user:change_role'),
  ('super_admin', 'facility:read'),
  ('super_admin', 'facility:manage'),
  ('super_admin', 'referral:create'),
  ('super_admin', 'referral:read_own'),
  ('super_admin', 'referral:read_facility'),
  ('super_admin', 'referral:update_facility'),
  ('super_admin', 'referral:complete'),
  ('super_admin', 'report:read_facility'),
  ('super_admin', 'report:read_system'),
  ('super_admin', 'report:export'),
  ('super_admin', 'audit:read'),
  ('super_admin', 'audit:export'),
  ('super_admin', 'settings:manage_facility'),
  ('super_admin', 'settings:manage_system'),
  ('facility_manager', 'facility:read'),
  ('facility_manager', 'facility:manage'),
  ('facility_manager', 'referral:read_facility'),
  ('facility_manager', 'report:read_facility'),
  ('facility_manager', 'report:export'),
  ('facility_manager', 'settings:manage_facility'),
  ('facility_officer', 'facility:read'),
  ('facility_officer', 'referral:read_facility'),
  ('facility_officer', 'referral:update_facility'),
  ('clinician', 'facility:read'),
  ('clinician', 'referral:read_facility'),
  ('clinician', 'referral:update_facility'),
  ('clinician', 'referral:complete'),
  ('chp', 'facility:read'),
  ('chp', 'referral:create'),
  ('chp', 'referral:read_own')
) AS v(role, permission)
WHERE NOT EXISTS (
  SELECT 1
  FROM role_permissions rp
  WHERE rp.role = v.role::app_role
    AND rp.permission = v.permission
);

CREATE INDEX IF NOT EXISTS idx_users_approval_created
  ON users(approval_status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_role_facility
  ON users(role, facility_id);

CREATE INDEX IF NOT EXISTS idx_role_permissions_permission
  ON role_permissions(permission);

CREATE INDEX IF NOT EXISTS idx_user_access_audit_target_created
  ON user_access_audit(target_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_access_audit_actor_created
  ON user_access_audit(actor_id, created_at DESC);


