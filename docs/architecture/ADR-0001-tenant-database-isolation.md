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

## Runtime Connection Contract

There are two database roles, not three independent product databases:

1. The shared `nexa_control` database is read by the platform kernel for tenant routing, placement, status, entitlements and operations.
2. The selected tenant database is that customer's complete EspoCRM database. It contains the existing Espo core tables and every Nexa customer-owned business table.

The application mediates between these roles. The databases do not join each other, hold cross-database foreign keys or participate in one distributed transaction.

```text
Request hostname
      |
      v
Nexa platform kernel -- ControlPlaneConnection --> nexa_control
      |                         |
      |                  tenant placement +
      |                  credential reference
      |                         |
      +---- SecretsProvider <---+
      |
      v
TenantContext + TenantConnectionFactory
      |
      v
Espo bootstrap / EntityManager -------------> nexa_tenant_<opaque-id>
                                               Espo core + Nexa modules
```

The platform kernel must run before Espo constructs its `EntityManager`, authentication services, tenant configuration or caches. It performs the following sequence:

1. Normalize and validate the trusted request hostname.
2. Use a dedicated control-plane connection to resolve `tenant_domain`, `tenant`, `tenant_placement`, `database_cluster` and `cell`.
3. Reject an unverified domain, inactive tenant, inactive placement, cluster or cell.
4. Exchange `credential_secret_ref` for restricted tenant credentials through a `SecretsProvider`.
5. Create an immutable `TenantContext` and tenant database parameters.
6. Construct a fresh tenant-scoped Espo runtime using those parameters.
7. Destroy or reset every tenant-scoped service when the request or job finishes.

Espo repositories and ordinary Nexa business modules receive only the tenant connection. Control-plane access is exposed through explicit platform interfaces, never through Espo entity relationships or raw cross-database SQL.

Operations that affect both roles use idempotent workflows and outbox events. For example, provisioning records a pending control-plane operation, creates and migrates the tenant database, verifies it and only then activates routing. Usage is committed to a tenant outbox with the business transaction and later aggregated into control-plane counters. A failure is retried or compensated; it is never hidden inside a distributed database transaction.

The detailed request, authentication, background-job, entitlement, provisioning and failure contracts are defined in [Nexa CRM SaaS Data Architecture](saas-data-architecture.md#runtime-communication-contract).

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
