# API Contracts

This document describes public browser-facing RPC contracts. It documents behavior, not SQL implementation.

## Conventions

- All secure RPCs require an authenticated Supabase session unless otherwise noted.
- UUID parameters must be valid UUID strings.
- `payload` parameters are JSON objects.
- Errors are returned by Supabase RPC calls and should be presented without exposing internal details.

## IAM RPCs

### `list_pending_users_secure()`

Purpose: list users awaiting approval.

Parameters: none.

Validation: caller must have administrative IAM access.

Permissions: user approval/manage permission.

Response: array of pending user records with profile and facility context.

Errors: authentication required, insufficient permission.

Example request:

```json
{}
```

Example response:

```json
[{ "id": "uuid", "email": "user@example.org", "approval_status": "pending" }]
```

### `list_users_secure()`

Purpose: list managed users.

Parameters: none.

Permissions: user management/read permission.

Response: array of user records.

### `approve_user_secure(target_user_id, facility_id, reason)`

Purpose: approve a pending user and assign a facility.

Parameters: target user UUID, facility UUID, administrative reason.

Validation: target exists and is pending; reason is required where enforced.

Permissions: super admin or IAM approver.

Response: updated user.

Possible errors: user not found, invalid lifecycle transition, missing reason, insufficient permission.

### `reject_user_secure(target_user_id, reason)`

Purpose: reject a pending user.

Response: updated user with rejected status.

### `suspend_user_secure(target_user_id, reason)`

Purpose: temporarily suspend an approved user.

Response: updated user.

### `reactivate_user_secure(target_user_id, reason)`

Purpose: restore a suspended user to approved access.

Response: updated user.

### `deactivate_user_secure(target_user_id, reason)`

Purpose: long-term removal of application access.

Response: updated user.

### `assign_user_facility_secure(target_user_id, facility_id, reason)`

Purpose: move a user to a facility.

Validation: facility exists; caller has assignment authority.

Response: updated user.

### `change_user_role_secure(target_user_id, new_role, reason)`

Purpose: change canonical role.

Validation: role is valid and caller is authorized.

Response: updated user.

## CHP Directory RPCs

### `upsert_chp_secure(payload)`

Purpose: create or update CHP directory records.

Parameters: CHP payload including facility, code, identity, contact, village, unit, training/enrollment flags, and notes.

Validation: facility scope, required identity fields, permission.

Response: CHP record.

Errors: access denied, validation failure, duplicate code.

## Referral Creation and Legacy Compatibility RPCs

### `create_referral_secure(payload)`

Purpose: create a patient and referral in a controlled workflow state.

Parameters: referral payload including patient details, facility, department, priority, clinical concern, reason, notes, and optional starting status.

Validation: create permission, facility scope, required patient name, required national ID for submitted referrals, duplicate active referral prevention, valid facility and department.

Permissions: `referral:create`.

Response: referral record.

Example request:

```json
{
  "payload": {
    "patient_name": "Jane Doe",
    "national_id": "12345678",
    "priority": "Routine",
    "referral_status": "submitted"
  }
}
```

Example response:

```json
{ "id": "uuid", "slip_no": "OHGL-2026-001", "referral_status": "submitted" }
```

### `save_referral_draft_secure(payload)`

Purpose: save a referral as draft or update a draft through the workflow engine.

Permissions: referral create permission.

### `update_referral_secure_full(p_referral_id, payload)`

Purpose: legacy-compatible secure field update for non-workflow fields and compatibility status handling.

Validation: update permission and referral ownership.

Compatibility note: new workflow progression should use command RPCs rather than legacy status updates.

## Workflow Command RPCs

All workflow command RPCs share this shape:

Parameters:

```json
{ "p_referral_id": "uuid", "payload": {} }
```

Validation:

- Authenticated user.
- Required permission.
- Referral exists.
- Referral ownership/facility access.
- Valid lifecycle transition.
- Command-specific payload requirements.

Response: updated referral record.

Common errors: referral not found, access denied, invalid transition, missing reason, missing outcome, invalid facility, invalid department.

Commands:

- `submit_referral_secure`
- `accept_referral_secure`
- `receive_patient_secure`
- `assign_referral_secure`
- `transfer_department_secure`
- `transfer_facility_secure`
- `triage_referral_secure`
- `start_consultation_secure`
- `record_investigation_secure`
- `record_treatment_secure`
- `record_outcome_secure`
- `request_followup_secure`
- `schedule_followup_secure`
- `complete_referral_secure`
- `close_referral_secure`
- `cancel_referral_secure`
- `reopen_referral_secure`
- `archive_referral_secure`

Example request:

```json
{
  "p_referral_id": "uuid",
  "payload": {
    "department_id": "uuid",
    "reason": "Assign to OPD clinician"
  }
}
```

Example response:

```json
{ "id": "uuid", "referral_status": "assigned", "referral_stage": "clinical" }
```

## Workflow Metadata RPCs

### `get_available_referral_actions(referral_id)`

Purpose: return current referral workflow state and allowed actions with metadata.

Parameters: referral UUID.

Validation: authenticated user and referral ownership/read access.

Permissions: read access plus action-specific enabled flags.

Response:

```json
{
  "status": "received",
  "stage": "receiving",
  "owner": "facility",
  "available_actions": [
    {
      "command": "assign_referral",
      "rpc_name": "assign_referral_secure",
      "label": "Assign Referral",
      "category": "Assignment",
      "confirmation": "Assign this referral?",
      "inputs": []
    }
  ]
}
```

### `get_workflow_action_definition(command_name)`

Purpose: return metadata for a workflow command.

Parameters: command name string.

Response: one action definition containing command, RPC name, label, description, category, confirmation, icon, color, inputs, and validation messages.

Possible errors: unknown workflow command.

### `get_workflow_reference_data(command_name)`

Purpose: return only reference data required by a command definition.

Parameters: command name string.

Response: keyed reference data arrays, such as `departments`, `facility_users`, `facilities`, `receiving_desks`, or `outcome_types`.

Example response:

```json
{
  "departments": [{ "value": "uuid", "label": "OPD" }],
  "facility_users": [{ "value": "uuid", "label": "Clinician Name", "role": "facility_officer" }]
}
```

## Audit and Notification Reads

Audit and notification reads are table/view queries through Supabase with RLS. They are not workflow commands and must remain scoped by authenticated user and facility permissions.
