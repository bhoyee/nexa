# ADR-0002: Shared-Schema Multi-Tenancy

- Status: Accepted
- Date: 2026-07-16
- Owners: Nexa CRM team
- Supersedes: [ADR-0001](ADR-0001-tenant-database-isolation.md)

## Context

Nexa will deeply customize the complete EspoCRM codebase and does not prioritize compatibility with future upstream EspoCRM releases. The team has chosen one shared MariaDB schema so CRM, marketing, automation, service and SaaS administration can use one coordinated data model and reporting surface.

EspoCRM 9.1.9 was designed for one organization per database. It does not automatically add tenant conditions to repositories, relationships, raw SQL, reports, scheduled jobs, caches, files or searches. Shared-schema tenancy therefore requires a deliberate application-wide security conversion; adding columns only to registration and login is insufficient.

## Decision

Use a shared-schema, row-scoped multi-tenant architecture:

1. EspoCRM core tables, Nexa business tables and Nexa SaaS administration tables use one logical MariaDB database per application cell.
2. Every tenant-owned row contains a mandatory `tenant_id` derived from a trusted immutable `TenantContext`.
3. `service_id` identifies the owning service only where a record is service-specific. Tenant ownership remains mandatory and cannot be replaced by service scope.
4. Espo's central ORM, repositories, relationships and record services automatically apply tenant scope to reads, writes, updates and deletes.
5. Raw SQL, reports, dashboards, imports, exports, APIs and background jobs must use approved tenant-scoped gateways.
6. Global reference tables such as plan and service definitions are explicitly registered as platform-global and cannot be accessed through an ordinary tenant-owned repository by accident.
7. Triggers and constraints may reject invalid writes, but application-level tenant scoping is the primary enforcement mechanism. Triggers are not treated as read isolation.

## Trusted Tenant Context

The platform resolves tenant identity from a verified hostname, workspace slug or signed session before authenticating the Espo user. Browser fields, query parameters and API payloads cannot choose or override tenant identity.

```text
verified host/workspace
        |
        v
TenantResolver --> TenantContext(tenant_id)
        |
        +--> login: user.tenant_id = TenantContext.tenant_id
        +--> ORM: every tenant-owned query receives tenant_id
        +--> jobs/cache/files/search/events receive tenant_id
        `--> service access checked through nexa_tenant_service
```

The authenticated principal is globally identified by `(tenant_id, user_id)`. Business records are globally identified by `(tenant_id, entity_type, entity_id)`.

## Service Scope

`tenant_id` answers who owns data. `service_id` answers which product service owns or meters service-specific data.

- Every customer-owned record has `tenant_id`.
- A marketing-send, automation execution or service-specific usage event may also have `service_id`.
- General CRM records such as Account and Contact do not require `service_id` merely because several services use them.
- Enabled services and limits are stored in `nexa_tenant_service` and checked by an `EntitlementService`.
- Disabling a service does not change ownership or make shared CRM records disappear.

## Mandatory Database Rules

- Tenant-owned primary lookups and indexes start with or include `tenant_id`.
- Business uniqueness is tenant-qualified, for example `UNIQUE (tenant_id, email_address)` where appropriate.
- Relationship tables carry tenant scope and both sides must belong to the same tenant.
- Updates and deletes include tenant scope in their predicates.
- New tenant-owned rows cannot persist without a trusted tenant context.
- Audit and outbox records always carry `tenant_id`; service-specific events also carry `service_id`.
- Platform-wide operations require a separate, explicit, audited execution path.

## Migration Strategy

Existing installations are converted with expand/backfill/enforce stages:

1. Inventory every Espo and Nexa table as global, tenant-owned, service-owned or derived.
2. Add nullable tenant columns and required indexes without breaking the running application.
3. Create the initial tenant and backfill existing rows, relationship tables and histories.
4. Deploy automatic ORM and job scoping.
5. Run cross-tenant tests and orphan/relationship validation.
6. Make `tenant_id` non-null and add final composite uniqueness and integrity constraints.
7. Remove temporary compatibility paths only after verification.

No blanket dynamic SQL migration may alter every table without an approved ownership and index manifest.

## Consequences

### Benefits

- One coordinated schema and migration sequence.
- Straightforward cross-module reporting inside a tenant.
- Simpler tenant registration than provisioning a database per customer.
- Deep product customization can use tenant-aware framework primitives everywhere.

### Costs and Risks

- One missing tenant scope can expose or alter another customer's data.
- Per-tenant restore and deletion require tested row-level workflows.
- Shared tables and indexes can become contention points.
- Every cache, file, search, job and integration path still needs tenant isolation.
- Future upstream EspoCRM upgrades are intentionally deprioritized because the ORM and core schema will be changed substantially.

## Non-Negotiable Gates

- The default repository path fails closed when no `TenantContext` exists.
- Two-tenant tests cover authentication, CRUD, relationships, reports, dashboards, jobs, APIs, imports, exports, cache, files and search.
- Static analysis or architecture tests reject direct unscoped access to tenant-owned tables outside approved platform gateways.
- No second real customer is onboarded until cross-tenant isolation tests pass.
- Security review is required for every platform-wide bypass.
