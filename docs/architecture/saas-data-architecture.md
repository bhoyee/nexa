# Nexa CRM SaaS Data Architecture

## Executive Decision

Use a **cell-based, database-per-tenant architecture** for transactional customer data.

Each customer's EspoCRM core records and every Nexa module built for that customer live together in one logical tenant database. A small shared control-plane database stores only SaaS routing and commercial metadata. Many logical tenant databases may share one MariaDB cluster; larger customers can later be moved to a dedicated cluster without changing the product data model.

This is the best balance for a two-developer team building on EspoCRM because it preserves Espo's single-database assumptions, strongly separates customers and avoids adding a fallible `tenant_id` filter to every existing Espo query.

## What “One Customer Database” Contains

For Customer A, `nexa_tenant_<opaque-id>` contains all of the following together:

- Existing EspoCRM Accounts, Contacts, Leads, Opportunities, Cases and activities.
- Users, teams, roles and tenant-specific configuration.
- Nexa campaigns, segments, consent, marketing-email and automation definitions.
- Conversations, scoring, attribution and integration configuration owned by that customer.
- An outbox of events that must be sent to queues or analytics.
- The tenant database's applied schema-version history.

The architecture does **not** put Espo core data in one database and new Nexa features in another. It separates customers from each other, not product modules from each other.

## Topology

```text
                         Nexa Control Plane
              tenants, domains, plans, placement, billing
                                  |
                    hostname -> tenant placement
                                  |
              +-------------------+-------------------+
              |                                       |
        Application Cell A                       Application Cell B
      shared Nexa/Espo code                    shared Nexa/Espo code
              |                                       |
       MariaDB Cluster A                       MariaDB Cluster B
      +-------+--------+                     +--------+-------+
      |                |                     |                |
 tenant_db_A      tenant_db_B            tenant_db_C      tenant_db_D
 core + Nexa      core + Nexa            core + Nexa      core + Nexa
```

A cell is a bounded group of application workers, queue workers, cache resources and database capacity. Tenant placement allows controlled scaling and limits the blast radius of an outage.

## Data Stores and Ownership

| Store | Contains | Must not contain |
|---|---|---|
| Control plane | Tenant ID, hostname, status, plan, entitlements, subscription references, database placement, schema version and aggregate usage | Contacts, deals, message bodies, attachments or ordinary CRM fields |
| Tenant transactional database | All Espo core and Nexa business records for exactly one tenant | Records belonging to another tenant |
| Object storage | Attachments, exports, imports and media under an immutable tenant prefix | Unscoped file keys or secrets in filenames |
| Queue/cache | Short-lived jobs, locks and cached values with tenant identity and cell identity | Jobs or keys without tenant context |
| Event/analytics platform | Append-only product, tracking and reporting events carrying tenant ID | Transactional source of truth for CRM records |
| Secrets manager | Database/provider credentials and encryption material referenced by opaque keys | Plaintext credentials in the control or tenant database |

MariaDB remains the transactional source of truth. High-volume web tracking, email events and analytics should move to a dedicated event/analytics platform when volume justifies it; they should not overload CRM tables.

## Request Routing

Every request follows this sequence:

1. Resolve the normalized hostname against `tenant_domain`.
2. Reject suspended, deleted or unverified tenants before Espo bootstraps.
3. Load tenant placement and an opaque database credential reference.
4. create an immutable `TenantContext` containing tenant, cell, region and request IDs.
5. Boot the Espo entity manager using only that tenant's database connection.
6. Add tenant and request IDs to logs, queue messages, cache keys and outbox events.
7. Clear tenant-scoped services after the request or job completes.

Never allow a browser, API caller or queue payload to choose a raw database name or credential reference.

## Isolation Controls

Database separation is necessary but not sufficient. The platform must also enforce:

- A database user that can access only the selected tenant database wherever operationally practical.
- Tenant-prefixed object-storage keys and signed URLs.
- Tenant-prefixed cache keys, locks and rate-limit counters.
- Tenant identity in every queued job, scheduled job and webhook delivery.
- Search indexes partitioned or filtered by tenant.
- Per-tenant encryption, export, retention and deletion workflows.
- Audit records for tenant routing, operator access and impersonation.
- Automated tests that attempt cross-tenant reads, writes, files, jobs and searches.

Platform operators do not receive silent SQL access through the CRM UI. Support access is time-limited, reason-bound and audited.

## Schema Management

### One Canonical Tenant Schema

All active tenant databases follow the same canonical schema version. Plan differences are enforced with entitlements, not different table structures.

### Espo Metadata First

Use Nexa metadata under `espocrm/custom/` for Espo entities, fields, relationships, indexes, scopes and layouts. Use explicit SQL migrations only for data transformations or structures that Espo rebuild cannot safely represent.

### Migration Process

1. Add an immutable migration and compatibility tests.
2. Validate it against a clean 9.1.9 database and a populated previous-version fixture.
3. Apply it to an internal tenant, then a staging cohort.
4. Roll it through cells in bounded batches.
5. Record filename, checksum, start/end time and result per tenant.
6. Pause automatically on error-rate or duration thresholds.
7. Use forward fixes; perform destructive cleanup only in a later release.

Use expand/migrate/contract for risky changes so old and new application versions can coexist during deployment.

## Control-Plane Model

The initial control-plane schema should evolve to include:

| Area | Principal records |
|---|---|
| Tenant registry | `tenant`, `tenant_domain`, status and region |
| Placement | cell, database cluster, opaque database name and credential reference |
| Commercial | plan, feature definition, entitlement and subscription |
| Usage | idempotent usage events and aggregated billing-period counters |
| Provisioning | idempotent create, suspend, restore, clone and delete operations |
| Schema fleet | desired version, current version, migration state and last successful backup |
| Operations | tenant health summary and audited operator actions |

Provider tokens and database passwords should be stored in a secrets manager; database rows store references only.

## Provisioning Sequence

1. Create a pending tenant record and reserve its slug/domain.
2. Select a healthy cell based on region and capacity.
3. Generate an opaque database name and restricted credentials.
4. Create the tenant database from the canonical schema or a tested template.
5. Run all migrations and seed required reference data.
6. Create the first tenant administrator and default roles.
7. Verify login, CRUD, queue, file and backup smoke tests.
8. Activate routing only after every verification succeeds.

Provisioning uses an idempotency key so retries cannot create duplicate tenants.

## Backups, Restore and Deletion

- Back up tenant databases independently and encrypt backups.
- Record recovery-point and recovery-time objectives by plan.
- Test restoration automatically using sampled backups.
- Restore into a new database and switch placement only after verification.
- Implement delayed deletion with legal-hold checks and auditable approval.
- Remove tenant object storage, search data, cache entries, analytics data and secrets as separate tracked steps.

## Local Development

The production architecture and developer workflow are separate concerns.

- Each developer runs an independent local MariaDB instance or container.
- Each local server can contain `nexa_control` and one or more disposable tenant databases.
- Both developers receive identical schemas through Git migrations and identical synthetic data through seeders.
- Neither developer shares a live database volume or uses SQL dumps for routine synchronization.
- Docker and XAMPP may serve the PHP application, but PHP extensions and MariaDB versions must match.

## Options Rejected

### One Shared CRM Schema with `tenant_id`

Rejected for the initial product. EspoCRM has 91 current entity definitions and no native tenant-context layer. Retrofitting every repository, relationship, raw query, job, search, cache entry and file operation would create a large permanent fork. MariaDB does not provide native row-level security comparable to a database policy that could serve as a reliable second guardrail.

This model could reduce database count, but its provisioning convenience is not worth the cross-customer disclosure risk and test surface for this team.

### One Physical Server per Tenant

Rejected as the default because it is needlessly expensive. Logical tenant databases share a managed MariaDB cluster within a cell. Dedicated infrastructure remains an enterprise or regulated-customer option.

### One Shared Espo Database per Subscription Plan

Rejected because plan changes would require customer-data migration and customers on the same plan would still lack isolation.

## Delivery Order

1. **Phase 0:** approve this architecture, align environments, establish migrations, fixtures and Git/CI.
2. **Tenancy spike:** prove hostname routing into two disposable tenant databases and cross-tenant isolation before broad UI work.
3. **Control plane:** implement tenant registry, placement, provisioning and schema-fleet tracking.
4. **Product modules:** build CRM and marketing modules into the canonical tenant schema.
5. **Event platform:** introduce outbox, queues and tracking ingestion before marketing automation volume.
6. **Cell operations:** add cohort migrations, backup/restore, observability and capacity placement.
7. **Production gate:** complete isolation, disaster-recovery, load and security tests before onboarding paying tenants.

## Non-Negotiable Launch Gate

No second real customer may be onboarded until automated evidence proves isolation across database connections, authentication, API access, scheduled jobs, queues, cache, files, search, exports, analytics and support impersonation.
