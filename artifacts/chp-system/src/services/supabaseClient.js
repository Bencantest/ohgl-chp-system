import { createClient } from '@supabase/supabase-js';

// Public values — safe to include in client code (same as original config.js).
// Override via VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY env vars.
const SUPABASE_URL =
  import.meta.env.VITE_SUPABASE_URL ||
  'https://mmtsvgmkmqojgfmtujtv.supabase.co';

const SUPABASE_ANON_KEY =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tdHN2Z21rbXFvamdobXR1anR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NzMwNzgsImV4cCI6MjA2NTA0OTA3OH0.JyWj7n9mfkfmFGRnscRQGqnPkdWIqJFCxEMuMz0F5s0';

export let sb = null;

export async function requireSupabase() {
  if (sb) return sb;
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    throw new Error('Supabase is not configured. Contact your system administrator.');
  }
  sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  return sb;
}

// Eagerly init so we have a client for auth.onAuthStateChange
requireSupabase().catch(err => console.error('[supabaseClient] init failed', err));
