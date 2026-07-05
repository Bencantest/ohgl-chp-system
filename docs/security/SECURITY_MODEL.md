# Security Model

OCHP is designed around backend-enforced least privilege. The browser UI is not trusted to enforce sensitive business rules.

## Authentication

Supabase Auth provides email/password authentication, password reset, session restoration, and logout. A Supabase Auth user must have a corresponding `public.users` profile before application access is granted.

## Authorization

Authorization is role and permission based. Roles map to permissions through `role_permissions`; secure RPCs evaluate permissions at execution time.

Canonical roles:

- `super_admin`
- `facility_manager`
- `facility_officer`
- `chp`

## Row Level Security

RLS is enabled on sensitive tables. Users can only read or act within their facility scope unless super admin rules apply. Secure views expose decrypted/filtered data where needed.

## Secure RPCs

Mutations of protected data should go through secure RPCs. RPCs are responsible for authentication checks, permission checks, ownership checks, validation, audit logging, and consistent side effects.

## Approval Workflow

New users enter a pending lifecycle state. Super admins approve, reject, suspend, reactivate, deactivate, assign facilities, and change roles through secure IAM RPCs. Administrative reasons are required and audited.

## Least Privilege

The frontend uses the public anon key and authenticated user session. Direct table writes are revoked where secure RPCs exist. UI hiding is a convenience, not a security boundary.

## Audit Logging

Security-relevant actions write `audit_logs` or `user_access_audit`. Referral workflow commands write audit records and timeline events.

## Threat Model

| Threat | Control |
| --- | --- |
| User tampers with frontend controls | Backend RPC validation and RLS |
| User calls RPC directly | Permission, owner, and transition validation |
| Cross-facility data access | `same_facility` checks and RLS |
| Unauthorized role escalation | IAM secure RPCs and super admin assertions |
| PHI exposure | Secure views, encryption where implemented, scoped reads |
| Silent clinical data overwrite | Versioned clinical notes and immutable timeline events |
| Missing accountability | Audit logs, assignment history, referral events |

## Security Assumptions

- Supabase project keys are managed correctly.
- HTTPS is used in production.
- Database migrations are applied in order.
- Admin accounts are protected operationally.
- Future integrations use backend-governed channels.
