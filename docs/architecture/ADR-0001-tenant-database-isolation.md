# ADR-0001: Cell-Based Database-per-Tenant Isolation

- Status: Accepted for initial implementation
- Date: 2026-07-14
- Owners: Nexa CRM team

The stakeholder-facing rationale and implementation recommendation are provided in [EspoCRM to Nexa CRM SaaS: Architecture Recommendation](espocrm-saas-architecture-recommendation.md).

## Context

EspoCRM 9.1.9 assumes one application database and does not natively scope every query, job, search, cache entry, file and integration by SaaS tenant. The local source contains 91 core and CRM entity definitions but no native tenant-context layer. Adding `tenant_id` to all upstream tables would create broad permanent changes and make a single missed filter a customer-data incident.

## Decision

Use a cell-based architecture with two logical database roles:

1. `nexa_control` is the small shared control-plane database. It contains tenant identity, database placement, domains, plans, entitlements, subscriptions, usage summaries and provisioning state. It must not contain ordinary CRM records.
2. Each tenant receives a logical database named with an opaque identifier such as `nexa_tenant_a1b2c3`. That one tenant database contains **both** the existing EspoCRM core tables and every Nexa CRM, marketing, automation and service table belonging to the customer.

Many logical tenant databases share one MariaDB cluster inside a cell. This decision does not require a separate physical database server for every customer. Large or regulated tenants can be moved to a dedicated cell later without changing their schema.

Local development uses one control database and one disposable tenant database per developer. Shared staging uses separate test tenants. Production credentials are unique per tenant or tenant group and stored in a secrets manager.

The complete topology, routing, migration, provisioning and operational design is defined in [Nexa CRM SaaS Data Architecture](saas-data-architecture.md).

## Consequences

- Strong isolation, incident containment and per-tenant backup/restore are practical.
- Espo relationships continue to work inside their expected database boundary.
- Provisioning, migrations and monitoring must operate across a fleet of logical databases.
- Cross-tenant reporting uses control-plane summaries or an analytics store, never joins across CRM databases.
- Multiple logical databases can share cluster capacity, keeping early infrastructure cost reasonable.

## Rules

- Keep all customer-owned core and Nexa business records together in that customer's tenant database.
- Never put ordinary CRM records in `nexa_control`.
- Never use a developer database dump as the schema-change mechanism.
- Every change is versioned, reviewed and tested on clean and upgrade databases.
- Tenant migrations are forward-compatible; destructive removal happens in a later release.
- Every queue message, cache key, file path, log and analytics event carries a tenant identifier.
- Do not onboard a second real customer until cross-tenant isolation tests pass across every storage and execution path.

## Revisit Conditions

Revisit cell size and shared runtime topology when measured load, operating cost or tenant count justifies it. Do not weaken logical database isolation merely to reduce early development work.
