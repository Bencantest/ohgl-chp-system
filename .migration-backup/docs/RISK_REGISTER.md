# Risk Register

| ID | Category | Risk | Likelihood | Impact | Mitigation | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RISK-001 | Technical | Live environment config differs from staging. | Medium | High | Use environment checklist and smoke tests. | Release operator | Open |
| RISK-002 | Security | Misconfigured Supabase RLS/RPC grants in production. | Low | High | Run migration validation, security tests, and staging smoke checks. | Database operator | Open |
| RISK-003 | Operational | Backup restore has not been rehearsed. | Medium | High | Restore to staging before production launch. | Database operator | Open |
| RISK-004 | Deployment | No npm lockfile may cause dependency drift. | Medium | Medium | Add lockfile in future hardening; monitor CI. | Engineering | Open |
| RISK-005 | Performance | Large production data volume may exceed synthetic baselines. | Medium | Medium | Monitor dashboard/tracker/report latency and add indexes as evidence requires. | Engineering | Open |
| RISK-006 | Data | Manual migration failure could leave partial state. | Low | High | Use release window, backup verification, and stop-on-failure runbook. | Database operator | Open |
| RISK-007 | Compliance | PHI exposure through logs or exports. | Low | High | Follow logging policy, use synthetic UAT data, review export handling. | Compliance owner | Open |
| RISK-008 | Security | Browser anon key misunderstood as secret. | Medium | Medium | Documentation states anon key is public and service-role keys are prohibited. | Release operator | Open |
| RISK-009 | Operational | Notification behavior not validated with live data. | Medium | Medium | Include notification UAT in staging. | UAT lead | Open |
| RISK-010 | Technical | Remaining global inline handlers may be fragile for future dynamic content. | Medium | Low | Use delegated event handling for future dynamic components. | Engineering | Open |
