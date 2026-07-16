# Nexa CRM Shared-Schema SaaS Data Architecture

## Executive Decision

Nexa uses a **shared-schema multi-tenant architecture**. EspoCRM core tables, Nexa product tables and SaaS administration tables live in one logical MariaDB database. Every customer-owned row is isolated by mandatory `tenant_id` scope enforced centrally by the application framework.

The team accepts a deep EspoCRM fork and does not prioritize future upstream upgrades. This makes a comprehensive ORM and schema conversion acceptable, but it does not reduce the security requirements: every data and execution path must fail closed when tenant context is absent.

## One Shared Database

A local environment uses one database such as `espocrm`. Production may later use several shared-schema cells for capacity or incident containment, but a cell still contains many tenants in one identical schema.

```text
                         Nexa application
              hostname/session -> TenantContext
                                |
                 ORM tenant scope + entitlements
                                |
                                v
                    Shared MariaDB database
        +----------------+----------------+----------------+
        |                |                |                |
   Espo CRM tables   Nexa modules   SaaS platform    audit/outbox
    tenant_id         tenant_id     tenant/services    tenant_id
```

There is no separate control-plane database and no database per tenant in the initial architecture.

## Data Classification

Every table must be registered in a reviewed ownership manifest.

| Classification | Required identity | Examples |
|---|---|---|
| Platform-global | No tenant column; privileged access only | plan definitions, service definitions, system reference data |
| Tenant-owned | `tenant_id NOT NULL` | users, accounts, contacts, leads, deals, activities, cases, campaigns |
| Service-owned | `tenant_id NOT NULL`, `service_id NOT NULL` | marketing sends, automation executions, service usage events |
| Tenant/service optional | `tenant_id NOT NULL`, nullable `service_id` | audit and outbox events shared across product modules |
| Derived external data | Tenant identity in partition/filter key | cache, files, search, analytics and queue payloads |

`tenant_id` is the security and ownership boundary. `service_id` is not added blindly to every record; it identifies a service-specific record or entitlement. Accounts and Contacts remain owned by a tenant even when CRM, marketing and service modules all use them.

## SaaS Platform Tables

The initial migration in `database/shared/migrations/` creates:

- `nexa_tenant` and `nexa_tenant_domain`.
- `nexa_plan_definition` and `nexa_service_definition`.
- `nexa_plan_service` and `nexa_tenant_service`.
- `nexa_tenant_subscription` and `nexa_usage_counter`.
- `nexa_provisioning_operation`.
- `nexa_audit_event` and `nexa_outbox_event`.

Nexa-owned tables use a `nexa_` prefix to avoid collisions with existing Espo table names.

## Runtime Tenant Contract

### Trusted Resolution

Tenant resolution occurs before Espo authentication:

1. Normalize the trusted hostname or workspace identifier.
2. Resolve an active `nexa_tenant` and verified `nexa_tenant_domain`.
3. Create an immutable `TenantContext` containing tenant, request and correlation identity.
4. Authenticate the user with both user credentials and `TenantContext.tenantId`.
5. Attach the context to ORM, ACL, cache, file, search, queue and audit services.
6. Clear all request-scoped identity after the request or job finishes.

Tenant identity never comes from a writable form field, arbitrary HTTP header or record payload.

### Login

A shared user table is tenant-owned. The login lookup is logically equivalent to:

```sql
SELECT *
FROM user
WHERE tenant_id = :trusted_tenant_id
  AND user_name = :user_name
  AND deleted = 0;
```

The same email or username may exist in different tenants. Tenant-qualified unique indexes enforce the chosen identity rules. Password reset and invitation links retain the verified workspace or hostname.

### Automatic ORM Scope

A central `TenantScopeApplier` must modify every Espo select, update and delete for registered tenant-owned entities. Developers should write normal repository code while the framework adds the mandatory predicate:

```sql
WHERE tenant_id = :trusted_tenant_id
```

The scope cannot be disabled by ordinary entity options. Platform-global access uses a separate interface with explicit permission and audit requirements.

Required framework components:

| Component | Responsibility |
|---|---|
| `TenantResolver` | Resolve and validate tenant from trusted routing data |
| `TenantContext` | Hold immutable tenant and request identity |
| `EntityOwnershipRegistry` | Classify every table/entity and its service-scope rule |
| `TenantScopeApplier` | Add tenant predicates to ORM reads, writes, updates and deletes |
| `TenantWriteGuard` | Reject missing or conflicting tenant/service identity |
| `EntitlementService` | Validate service availability and limits from `nexa_tenant_service` |
| `PlatformDataGateway` | Permit reviewed cross-tenant operations with audit records |
| `TenantContextScope` | Clear context after each request or long-running job iteration |

### Writes and Database Guards

Application services derive `tenant_id` from `TenantContext`; they never trust a supplied record value. Service-specific writers derive or validate `service_id` through the entity ownership registry and entitlement service.

Database triggers may reject missing or inconsistent tenant identity during the migration, but they are defense-in-depth for writes only. They do not replace ORM filtering for reads. Foreign keys, composite uniqueness and cross-tenant relationship validation provide additional protection.

### Relationships

Relationship and junction tables carry tenant scope. A relationship can be created only when both records belong to the current tenant. Repository joins constrain every tenant-owned alias, not only the first table.

### Reports and Dashboards

Report builders, dashboard widgets and aggregates run through tenant-scoped query services. Every base table and joined tenant-owned table receives the current tenant condition. Service availability is checked separately when a report belongs to a paid service.

A normal tenant report cannot request another tenant ID. Platform analytics uses a separate governed path and records the operator or system purpose.

### Scheduled and Background Jobs

Every job contains a signed or server-generated `tenant_id`, job ID and correlation ID. Service jobs also carry `service_id`. A worker creates a fresh tenant context, revalidates tenant and service status, runs scoped repositories and clears context before accepting another job.

Global schedulers may enumerate active tenants using the platform gateway, then emit one tenant-scoped job per tenant. A long-running worker must never retain an authenticated user, ORM identity map or cache namespace across tenants.

## Service Entitlements

Service access is modeled separately from data ownership:

```text
nexa_plan_definition
        |
        +--> nexa_plan_service --> nexa_service_definition
                                      |
nexa_tenant_subscription              |
        |                              |
nexa_tenant ----------------> nexa_tenant_service
```

`nexa_tenant_service` records enabled status, limits and tenant overrides. Disabling a service blocks its commands and scheduled jobs but does not remove or reassign the tenant's core CRM records.

## Audit and Events

Espo's creator, modifier, assignment, authentication log, action history, stream and audited fields remain useful. Nexa additionally records tenant-aware security and integration activity in `nexa_audit_event` and `nexa_outbox_event`.

An audit identity includes:

- `tenant_id`.
- Optional `service_id`.
- Actor type and local Espo user where applicable.
- Action, subject, timestamp, request and correlation IDs.
- Redacted metadata appropriate for retention and privacy policy.

Tenant ID is derived from trusted runtime context, not event payload. Support impersonation records both operator identity and target tenant user.

## Schema Conversion

### Stage 1: Inventory

Create a machine-readable manifest classifying every Espo and Nexa table. Identify relationship tables, raw SQL, uniqueness rules, reports and scheduled jobs. No table is assumed global merely because it lacks a visible customer field.

### Stage 2: Expand

Migration `0002_expand_espocrm_tenant_scope.sql` inventories all 136 EspoCRM 9.1.9 tables. It adds indexed `tenant_id` and nullable `service_id` columns to 133 tables, backfills current records and tenant-qualifies 56 business unique indexes. `address_country`, `extension` and `system_data` are the explicit platform-global allowlist. Nine MariaDB `AUTO_INCREMENT` sequence indexes remain globally unique because their sequence column must lead the key.

During the transition, new rows receive the stable legacy-local tenant by default so existing single-tenant Espo code cannot create null tenant rows. This default is temporary and must be removed when automatic ORM scoping is enforced.

### Stage 3: Backfill

Create a baseline tenant for existing development data. Backfill parent records first, then relationships, histories and derived records. Validate orphan counts and cross-tenant relationships after every batch.

### Stage 4: Enforce

Deploy automatic ORM scope and write guards, then make tenant columns non-null. Replace global unique indexes with tenant-qualified indexes where business identity is tenant-local.

### Stage 5: Prove Isolation

Run two-tenant attack-oriented tests across authentication, CRUD, relationships, APIs, reports, dashboards, imports, exports, jobs, cache, files, search, audit and integrations. No real second customer is allowed before these tests pass.

## Shared-Schema Index Rules

- Frequent tenant queries use indexes beginning with `tenant_id`.
- Tenant-local uniqueness includes `tenant_id`.
- Service-heavy access commonly uses `(tenant_id, service_id, ...)`.
- Soft-delete and status columns follow tenant identity in selective indexes.
- Indexes are based on measured query plans; do not add both tenant and service to every index automatically.

## Cache, Files, Search and Analytics

Database filtering alone is not enough:

- Cache keys begin with tenant identity.
- Object-storage paths use immutable tenant prefixes.
- Search documents contain an enforced tenant filter field.
- Queue messages include trusted tenant context.
- Analytics events carry tenant and optional service identity.
- Rate limits and distributed locks are tenant-namespaced.

## Registration and Provisioning

1. Validate and reserve a tenant slug/domain.
2. Insert `nexa_tenant` with provisioning status.
3. Create its subscription and enabled `nexa_tenant_service` rows.
4. Create the first Espo user with the new `tenant_id`.
5. Seed default roles, teams and tenant configuration using the same tenant context.
6. Run tenant-scoped login and CRUD smoke tests.
7. Activate the tenant only after verification succeeds.

Provisioning uses an idempotency key so a retry cannot create duplicate tenants or administrators.

## Backup, Export and Deletion

Shared-schema backup is database-wide. Tenant-level recovery requires tested logical export and restore tools that preserve IDs and relationships while enforcing the target tenant. Tenant deletion is a dependency-ordered, auditable workflow across database rows, files, cache, search, analytics and provider data.

Enterprise physical isolation can later be implemented with a dedicated shared-schema cell, but it is not the initial tenancy model.

## Local Development

Each developer runs one independent `espocrm` database through Docker or MariaDB 10.11 used by XAMPP. Both apply the same `database/shared/migrations/` sequence and synthetic seeds. Git synchronizes schema definitions; developers never exchange live dumps for routine collaboration.

Local fixtures must include at least two synthetic tenants with overlapping usernames and record names so isolation tests can detect missing scope.

## Delivery Order

1. Approve ADR-0002 and the table-ownership rules.
2. Create the complete Espo table ownership/index manifest.
3. Implement `TenantContext`, resolver and automatic ORM scope.
4. Apply expand and backfill migrations to core tables.
5. Convert authentication, relationships, reports, jobs and external storage.
6. Enforce non-null tenant constraints and tenant-qualified uniqueness.
7. Complete the two-tenant isolation test gate.
8. Build feature modules only on the tenant-aware repository and entitlement contracts.

## Non-Negotiable Launch Gate

No second real customer may be onboarded until automated evidence proves isolation across authentication, ORM queries, raw SQL, relationships, APIs, scheduled jobs, queues, cache, files, search, exports, analytics, audit and support impersonation.
