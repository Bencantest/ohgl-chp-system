-- 20260706_000019_coverage_areas.sql
-- Stores operational coverage planning status independently from CHP account/lifecycle active state.

DO $$ BEGIN
  CREATE TYPE coverage_status AS ENUM ('active', 'partial', 'none');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS coverage_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id uuid NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  sub_location text NOT NULL,
  coverage_status coverage_status NOT NULL DEFAULT 'none',
  required_chps integer NOT NULL DEFAULT 0 CHECK (required_chps >= 0),
  assigned_chps integer NOT NULL DEFAULT 0 CHECK (assigned_chps >= 0),
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT coverage_areas_facility_sub_location_key UNIQUE (facility_id, sub_location)
);

CREATE INDEX IF NOT EXISTS idx_coverage_areas_facility
  ON coverage_areas(facility_id, sub_location);

ALTER TABLE coverage_areas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS coverage_areas_select ON coverage_areas;
DROP POLICY IF EXISTS coverage_areas_no_direct_insert ON coverage_areas;
DROP POLICY IF EXISTS coverage_areas_no_direct_update ON coverage_areas;
DROP POLICY IF EXISTS coverage_areas_no_direct_delete ON coverage_areas;

CREATE POLICY coverage_areas_select ON coverage_areas
  FOR SELECT
  USING (public.same_facility(facility_id) AND public.has_permission('facility:read'));

CREATE POLICY coverage_areas_no_direct_insert ON coverage_areas
  FOR INSERT
  WITH CHECK (false);

CREATE POLICY coverage_areas_no_direct_update ON coverage_areas
  FOR UPDATE
  USING (false)
  WITH CHECK (false);

CREATE POLICY coverage_areas_no_direct_delete ON coverage_areas
  FOR DELETE
  USING (false);

CREATE OR REPLACE FUNCTION upsert_coverage_area_secure(payload jsonb)
RETURNS coverage_areas
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  fid uuid := nullif(payload->>'facility_id', '')::uuid;
  subloc text := nullif(trim(coalesce(payload->>'sub_location', '')), '');
  status_value text := lower(nullif(trim(coalesce(payload->>'coverage_status', 'none')), ''));
  required_count integer := greatest(coalesce((payload->>'required_chps')::integer, 0), 0);
  assigned_count integer := greatest(coalesce((payload->>'assigned_chps')::integer, 0), 0);
  note_value text := nullif(trim(coalesce(payload->>'notes', '')), '');
  result coverage_areas;
BEGIN
  IF fid IS NULL OR NOT EXISTS (SELECT 1 FROM facilities f WHERE f.id = fid) THEN
    RAISE EXCEPTION 'A valid facility is required.';
  END IF;
  IF NOT public.same_facility(fid) OR NOT public.has_permission('facility:manage') THEN
    RAISE EXCEPTION 'You do not have permission to update coverage for this facility.';
  END IF;
  IF subloc IS NULL THEN
    RAISE EXCEPTION 'Sub-location is required.';
  END IF;
  IF status_value NOT IN ('active', 'partial', 'none') THEN
    RAISE EXCEPTION 'Invalid coverage status.';
  END IF;

  INSERT INTO coverage_areas (
    facility_id,
    sub_location,
    coverage_status,
    required_chps,
    assigned_chps,
    reviewed_by,
    reviewed_at,
    notes,
    updated_at
  ) VALUES (
    fid,
    subloc,
    status_value::coverage_status,
    required_count,
    assigned_count,
    auth.uid(),
    now(),
    note_value,
    now()
  )
  ON CONFLICT (facility_id, sub_location) DO UPDATE SET
    coverage_status = excluded.coverage_status,
    required_chps = excluded.required_chps,
    assigned_chps = excluded.assigned_chps,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    notes = excluded.notes,
    updated_at = now()
  RETURNING * INTO result;

  RETURN result;
END;
$$;

REVOKE EXECUTE ON FUNCTION upsert_coverage_area_secure(jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION upsert_coverage_area_secure(jsonb) TO authenticated;
GRANT SELECT ON coverage_areas TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON coverage_areas FROM authenticated;