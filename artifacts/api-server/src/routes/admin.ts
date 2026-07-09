import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// Roles that can be granted via the invite flow
const INVITABLE_ROLES = new Set([
  'clinician',
  'receptionist',
  'monitor',
  'facility_manager',
  'facility_officer',
]);

/**
 * POST /api/admin/invite-staff
 *
 * Body: { email, full_name, role, facility_id }
 * Headers: Authorization: Bearer <supabase_jwt>
 *
 * Creates a Supabase auth invite (sends "Set password" email) and
 * pre-creates the user profile row with approval_status: approved.
 */
router.post('/invite-staff', async (req, res) => {
  // Check service role is configured
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return res.status(503).json({
      error:
        'Staff invitation is not yet configured. ' +
        'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables on the API server.',
    });
  }

  // Verify caller JWT
  const authHeader = req.headers.authorization;
  const token = authHeader?.replace(/^Bearer\s+/i, '').trim();
  if (!token) return res.status(401).json({ error: 'Authorization header is required.' });

  const { email, full_name, role, facility_id } = req.body || {};

  if (!email || !full_name || !role || !facility_id) {
    return res.status(400).json({ error: 'email, full_name, role, and facility_id are required.' });
  }

  if (!INVITABLE_ROLES.has(role)) {
    return res.status(400).json({ error: `Invalid role "${role}". Allowed: ${[...INVITABLE_ROLES].join(', ')}.` });
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Verify caller is super_admin
  const { data: callerData, error: callerErr } = await adminClient.auth.getUser(token);
  if (callerErr || !callerData?.user) {
    return res.status(401).json({ error: 'Invalid or expired authentication token.' });
  }

  const { data: callerProfile, error: profileErr } = await adminClient
    .from('users')
    .select('role')
    .eq('id', callerData.user.id)
    .maybeSingle();

  if (profileErr || callerProfile?.role !== 'super_admin') {
    return res.status(403).json({ error: 'Only super_admin can invite staff members.' });
  }

  // Send the invite email via Supabase admin
  const { data: inviteData, error: inviteErr } = await adminClient.auth.admin.inviteUserByEmail(email, {
    data: { full_name, role, facility_id },
    redirectTo: process.env.APP_URL ? `${process.env.APP_URL}/` : undefined,
  });

  if (inviteErr) {
    return res.status(400).json({ error: inviteErr.message });
  }

  // Pre-create the profile so the user can log in immediately after setting their password
  if (inviteData?.user?.id) {
    const { error: upsertErr } = await adminClient.from('users').upsert(
      {
        id: inviteData.user.id,
        email,
        full_name,
        role,
        facility_id,
        active: true,
        approval_status: 'approved',
        phone: '',
      },
      { onConflict: 'id' },
    );
    if (upsertErr) {
      // Non-fatal — invite email was sent; profile will be created on first login
      console.warn('[admin/invite-staff] profile upsert failed', upsertErr.message);
    }
  }

  // Write audit log
  try {
    await adminClient.from('audit_logs').insert({
      actor_id: callerData.user.id,
      action: 'invite_staff',
      table_name: 'users',
      record_id: inviteData?.user?.id || null,
      facility_id,
      changes: { email, role, facility_id, invited_by: callerData.user.id },
    });
  } catch (auditErr) {
    console.warn('[admin/invite-staff] audit log failed', auditErr);
  }

  return res.status(200).json({
    success: true,
    message: `Invitation sent to ${email}. They will receive a "Set your password" email.`,
  });
});

export default router;
