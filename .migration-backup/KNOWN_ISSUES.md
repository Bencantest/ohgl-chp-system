# Known Issues Register

| ID | Severity | Issue | Impact | Workaround | Target Fix Version | Status |
| --- | --- | --- | --- | --- | --- | --- |
| KI-001 | Medium | Live Supabase smoke tests are not automated in CI. | Production-only configuration issues may be caught late. | Run manual staging smoke checklist before release. | v1.0.0 | Open |
| KI-002 | Medium | Browser export flows require manual UAT. | PDF/CSV/Excel issues may not be detected by static tests. | Execute report export UAT in staging. | v1.0.0 | Open |
| KI-003 | Medium | Notification delivery requires live data/configuration validation. | Users may miss operational notifications if config/data is incomplete. | Verify notification records and mark-read behavior during staging UAT. | v1.0.0 | Open |
| KI-004 | Low | No npm lockfile exists. | CI dependency resolution may vary over time. | Use reviewed dependency versions; generate lockfile in a future hardening task. | v1.0.0 | Open |
| KI-005 | Low | RTO/RPO targets are documented but not yet rehearsed. | Recovery confidence is not fully proven. | Restore latest backup to staging before production launch. | v1.0.0 | Open |
| KI-006 | Low | Some legacy inline handlers remain by design through `window` exports. | Future dynamic UI changes could repeat event-binding regressions. | Prefer delegated handlers for newly dynamic views. | v1.1.0 | Open |

## Critical

No critical known issues identified by automated validation.

## High

No high-severity known issues identified by automated validation.
