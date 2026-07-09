# Oasis Community Health Platform (OCHP)

Oasis Community Health Platform is a web-based healthcare operations system for Community Health Promoter referral creation, facility receiving workflows, clinical referral progression, auditability, and future health-system integrations.

Project code name: ODSL Siaya CHP Engagement & Referral Tracking System.

## Vision

OCHP supports safer, more accountable community-to-facility care coordination. The platform is designed for healthcare organizations, county governments, NGOs, donors, and technical partners that need traceable referral operations and a foundation for broader clinical modules.

## Architecture Overview

OCHP uses a static browser frontend with Supabase Auth and PostgreSQL. Sensitive workflow and identity behavior is enforced in the backend through Row Level Security, secure views, and secure RPCs.

Key principles:

- Backend is the source of truth for workflow transitions and permissions.
- Frontend renders data and backend-provided workflow metadata.
- Protected mutations use secure RPCs.
- Referral timelines, clinical notes, assignment history, SLA events, and audit logs preserve accountability.
- Backward compatibility is maintained while canonical workflow fields evolve.

## Technology Stack

- Frontend: static HTML, CSS, JavaScript ES modules.
- Backend: Supabase Auth and PostgreSQL.
- Security: Supabase sessions, RLS, secure RPCs, role/permission model.
- Data protection: encrypted PHI fields where implemented, secure views, audit logging.
- Documentation: Markdown and Mermaid diagrams.

## Repository Structure

```text
docs/
  architecture/  System, domain, roadmap, and contribution docs
  adr/           Architecture Decision Records
  api/           RPC/API contracts
  database/      Database and migration guidelines
  security/      Security model and threat model
  workflows/     Workflow engine and healthcare workflows
src/
  components/    Reusable UI components
  pages/         Application pages
  services/      Supabase, auth, workflow, notification services
  styles/        CSS layers
  utils/         Shared utilities
supabase/
  migrations/    Forward database migrations
  schema.sql     Baseline schema artifact
```

## Getting Started

1. Configure `config.js`:

```js
window.OHGL_SUPABASE_URL = 'https://PROJECT.supabase.co';
window.OHGL_SUPABASE_ANON_KEY = 'public-anon-key';
```

2. Apply Supabase schema/migrations in order in a non-production environment first.
3. Serve the static frontend over HTTPS for production.
4. Create or bootstrap an initial super admin user.
5. Review security and architecture docs before enabling live patient data.

## Deployment

Host the frontend on a secure static host and connect it to the Supabase project. Production deployments should follow:

- [Deployment Operations](docs/DEPLOYMENT_OPERATIONS.md)
- [Production Readiness](docs/PRODUCTION_READINESS.md)
- [Migration Plan](docs/MIGRATION_PLAN.md)
- [Test Plan](docs/TEST_PLAN.md)

## Documentation

- [Documentation Index](docs/README.md)
- [System Architecture](docs/architecture/SYSTEM_ARCHITECTURE.md)
- [Domain Model](docs/architecture/DOMAIN_MODEL.md)
- [Workflow Engine](docs/workflows/WORKFLOW_ENGINE.md)
- [Healthcare Workflows](docs/workflows/WORKFLOWS.md)
- [Security Model](docs/security/SECURITY_MODEL.md)
- [Security Hardening Audit](docs/security/SECURITY_HARDENING_AUDIT.md)
- [API Contracts](docs/api/API_CONTRACTS.md)
- [Database Guidelines](docs/database/DATABASE_GUIDELINES.md)
- [Architecture Decision Records](docs/adr/README.md)
- [Repository Structure](docs/architecture/REPOSITORY_STRUCTURE.md)
- [Coding Standards](docs/architecture/CODING_STANDARDS.md)
- [Contributor Guide](docs/architecture/CONTRIBUTING.md)
- [Environment Strategy](docs/ENVIRONMENTS.md)
- [Deployment Guide](deployments/DEPLOYMENT.md)
- [Testing and QA](docs/TESTING_QA.md)
- [Production Readiness Report](docs/PRODUCTION_READINESS_REPORT.md)
- [Release Management](docs/releases/README.md)
- [Roadmap](docs/architecture/ROADMAP.md)

## Roadmap

Completed:

- OCHP-001 Identity & Access
- OCHP-002A Referral Foundation
- OCHP-002B Workflow Command Engine
- OCHP-002C Workflow UI Integration

Planned:

- OCHP-002C.1 Workflow Metadata Engine
- OCHP-002D Clinical Operations
- OCHP-003 Laboratory Module
- OCHP-004 Radiology Module
- OCHP-005 Pharmacy Module
- OCHP-006 Inpatient Module
- OCHP-007 Analytics & Dashboards
- OCHP-008 External Integrations
- OCHP-009 Mobile CHP Application
- OCHP-010 Multi-Tenant County Deployment

## License

License to be confirmed by the project owner before external distribution.



