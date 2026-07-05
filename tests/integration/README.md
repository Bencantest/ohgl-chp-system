# Integration Test Template

Use this folder for tests that call a development or staging Supabase project.

Required setup:

- Synthetic test users.
- Dedicated test facility.
- Environment-specific Supabase URL and anon key.
- No production PHI.

Suggested contracts:

- Auth session bootstrap.
- `list_pending_users_secure` access by super admin.
- `get_available_referral_actions` response shape.
- Secure view read scoping by facility.
