-- 20260705_000011_iam_permission_stabilization.sql
-- OCHP Sprint 1 Task 8: final IAM validation stabilization.
-- Keeps the Sprint 1 permission tables as source of truth while preserving
-- compatibility with existing RLS/functions that still request legacy keys.

CREATE OR REPLACE FUNCTION normalized_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT CASE public.current_user_role()::text
    WHEN 'facility_admin' THEN 'facility_manager'
    WHEN 'technician' THEN 'facility_officer'
    WHEN 'viewer' THEN 'chp'
    ELSE public.current_user_role()::text
  END
$$;

CREATE OR REPLACE FUNCTION role_permissions(p_role text)
RETURNS text[]
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  WITH canonical_role AS (
    SELECT CASE p_role
      WHEN 'facility_admin' THEN 'facility_manager'
      WHEN 'technician' THEN 'facility_officer'
      WHEN 'viewer' THEN 'chp'
      ELSE p_role
    END AS role_name
  ), base_permissions AS (
    SELECT rp.permission_key
    FROM public.role_permissions rp
    JOIN canonical_role cr ON rp.role::text = cr.role_name
  ), compatibility_permissions AS (
    SELECT permission_key FROM base_permissions
    UNION
    SELECT '*' WHERE (SELECT role_name FROM canonical_role) = 'super_admin'
    UNION
    SELECT 'referral:read' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'referral:read_facility')
    UNION
    SELECT 'referral:update' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'referral:update_facility')
    UNION
    SELECT 'report:read' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key IN ('report:read_facility', 'report:read_system'))
    UNION
    SELECT 'patient:read' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key IN ('facility:manage', 'referral:read_facility'))
    UNION
    SELECT 'patient:write' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'facility:manage')
    UNION
    SELECT 'chp:read' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'facility:manage')
    UNION
    SELECT 'chp:create' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'facility:manage')
    UNION
    SELECT 'chp:update' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'facility:manage')
    UNION
    SELECT 'chp:delete' WHERE EXISTS (SELECT 1 FROM base_permissions WHERE permission_key = 'facility:manage')
  )
  SELECT coalesce(array_agg(DISTINCT permission_key ORDER BY permission_key), ARRAY[]::text[])
  FROM compatibility_permissions
$$;

CREATE OR REPLACE FUNCTION has_permission(required text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  perms text[];
BEGIN
  perms := public.role_permissions(public.normalized_user_role());
  IF perms IS NULL THEN
    RETURN false;
  END IF;
  RETURN '*' = ANY(perms)
    OR required = ANY(perms)
    OR EXISTS (
      SELECT 1
      FROM unnest(perms) AS p
      WHERE right(p, 2) = ':*'
        AND required LIKE left(p, length(p) - 1) || '%'
    );
END;
$$;

CREATE OR REPLACE FUNCTION notify_user_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_rec record;
BEGIN
  IF (tg_op = 'INSERT') THEN
    FOR admin_rec IN SELECT id FROM users WHERE role = 'super_admin' AND active = true LOOP
      INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
      VALUES (null, admin_rec.id, 'User Created', 'A new user profile for ' || new.full_name || ' (' || new.email || ') has been created.', 'user_created', new.id::text);
    END LOOP;

    IF new.facility_id IS NOT NULL THEN
      FOR admin_rec IN SELECT id FROM users WHERE facility_id = new.facility_id AND role = 'facility_manager' AND active = true LOOP
        INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
        VALUES (new.facility_id, admin_rec.id, 'User Created', 'A new user profile for ' || new.full_name || ' (' || new.email || ') has been created for your facility.', 'user_created', new.id::text);
      END LOOP;
    END IF;

  ELSIF (tg_op = 'UPDATE') THEN
    IF old.active = true AND new.active = false THEN
      FOR admin_rec IN SELECT id FROM users WHERE role = 'super_admin' AND active = true LOOP
        INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
        VALUES (null, admin_rec.id, 'User Suspended', 'The user account for ' || new.full_name || ' (' || new.email || ') has been suspended.', 'user_suspended', new.id::text);
      END LOOP;

      IF new.facility_id IS NOT NULL THEN
        FOR admin_rec IN SELECT id FROM users WHERE facility_id = new.facility_id AND role = 'facility_manager' AND active = true LOOP
          INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
          VALUES (new.facility_id, admin_rec.id, 'User Suspended', 'The user account for ' || new.full_name || ' (' || new.email || ') has been suspended.', 'user_suspended', new.id::text);
        END LOOP;
      END IF;
    END IF;
  END IF;

  RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION notify_referral_status_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_rec record;
  pat_name text;
  recipient_rec record;
  notif_title text;
  notif_msg text;
  notif_type text;
BEGIN
  SELECT * INTO ref_rec FROM referrals WHERE id = new.referral_id;
  IF ref_rec.id IS NULL THEN
    RETURN new;
  END IF;

  BEGIN
    pat_name := pgp_sym_decrypt(ref_rec.patient_name_ciphertext, current_setting('app.encryption_key', true));
  EXCEPTION WHEN others THEN
    pat_name := 'Patient';
  END;

  CASE new.status::text
    WHEN 'Submitted' THEN
      notif_type := 'referral_submitted';
      notif_title := 'Referral Submitted';
      notif_msg := 'New referral ' || ref_rec.slip_no || ' for ' || pat_name || ' has been submitted.';
    WHEN 'Under Review' THEN
      notif_type := 'referral_approved';
      notif_title := 'Referral Approved';
      notif_msg := 'Referral ' || ref_rec.slip_no || ' for ' || pat_name || ' has been approved for review.';
    WHEN 'Received' THEN
      notif_type := 'referral_received';
      notif_title := 'Referral Received';
      notif_msg := 'Referral ' || ref_rec.slip_no || ' for ' || pat_name || ' has been received at the facility.';
    WHEN 'Completed' THEN
      notif_type := 'referral_completed';
      notif_title := 'Referral Completed';
      notif_msg := 'Referral ' || ref_rec.slip_no || ' for ' || pat_name || ' has been completed.';
    WHEN 'Cancelled' THEN
      notif_type := 'referral_rejected';
      notif_title := 'Referral Rejected';
      notif_msg := 'Referral ' || ref_rec.slip_no || ' for ' || pat_name || ' was cancelled.';
    WHEN 'Closed' THEN
      notif_type := 'referral_rejected';
      notif_title := 'Referral Rejected';
      notif_msg := 'Referral ' || ref_rec.slip_no || ' for ' || pat_name || ' was closed.';
    ELSE
      RETURN new;
  END CASE;

  IF ref_rec.created_by IS NOT NULL AND ref_rec.created_by != coalesce(new.responsible_user_id, '00000000-0000-0000-0000-000000000000'::uuid) THEN
    INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
    VALUES (ref_rec.facility_id, ref_rec.created_by, notif_title, notif_msg, notif_type, ref_rec.id::text);
  END IF;

  FOR recipient_rec IN
    SELECT id FROM users
    WHERE facility_id = ref_rec.facility_id
      AND role IN ('facility_manager', 'facility_officer', 'clinician')
      AND active = true
      AND id != coalesce(new.responsible_user_id, '00000000-0000-0000-0000-000000000000'::uuid)
  LOOP
    INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
    VALUES (ref_rec.facility_id, recipient_rec.id, notif_title, notif_msg, notif_type, ref_rec.id::text);
  END LOOP;

  FOR recipient_rec IN
    SELECT id FROM users
    WHERE role = 'super_admin'
      AND active = true
      AND id != coalesce(new.responsible_user_id, '00000000-0000-0000-0000-000000000000'::uuid)
  LOOP
    INSERT INTO notifications (facility_id, user_id, title, message, type, resource_id)
    VALUES (null, recipient_rec.id, notif_title, notif_msg, notif_type, ref_rec.id::text);
  END LOOP;

  RETURN new;
END;
$$;
