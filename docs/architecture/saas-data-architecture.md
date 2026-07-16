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

## Runtime Communication Contract

### Two Database Roles

The phrase "EspoCRM database" means the selected tenant transactional database. There is no third shared database containing Espo records.

| Connection role | Opened by | Permitted data | Prohibited behavior |
|---|---|---|---|
| `ControlPlaneConnection` | Nexa platform kernel and platform workers | Tenant registry, domain, placement, plan, entitlement, usage summary and operations | Reading or writing Contacts, Accounts, Deals, messages or other customer records |
| `TenantConnection` | Tenant-scoped Espo runtime and tenant workers | All Espo core tables and Nexa business tables for one tenant | Accessing another tenant database or control-plane tables |
| Cluster administrator | Provisioning and migration workers only | Database creation, restricted-user creation, migrations and verified operational actions | Serving browser requests or ordinary product queries |

A runtime process may temporarily hold a control-plane connection and one tenant connection, but application code treats them as separate units of work. There are no cross-database joins, foreign keys or atomic commits between them.

### Runtime Components

The modular monolith needs a platform kernel in front of Espo's normal bootstrap:

| Component | Responsibility |
|---|---|
| `TrustedHostResolver` | Normalize the gateway-provided hostname and reject untrusted forwarding headers |
| `TenantPlacementResolver` | Query the control-plane routing records and enforce tenant, placement, cluster and cell status |
| `SecretsProvider` | Exchange an opaque credential reference for tenant credentials without exposing them to domain code |
| `TenantContext` | Hold immutable tenant, cell, region, request, entitlement-version and routing-version identity |
| `TenantConnectionFactory` | Create database parameters and a connection restricted to the selected tenant database |
| `TenantRuntimeFactory` | Construct tenant-scoped Espo configuration, ORM, authentication, ACL, metadata, cache and file services |
| `TenantRuntimeScope` | Tear down connections, identity maps, configuration overlays and caches after every request or job |

Espo's shared filesystem configuration cannot remain the source of customer-specific settings in a shared cell. The tenancy proof of concept must split immutable platform configuration from tenant configuration and provide tenant-aware configuration/cache adapters before Espo boots. It must never rewrite one global `data/config.php` while serving concurrent tenants.

### Request Routing

```text
Browser or API client
        |
        | Host: customer-a.nexa.example
        v
Gateway / trusted proxy
        |
        v
Nexa platform kernel
        |
        +-- ControlPlaneConnection --> tenant_domain
        |                              tenant
        |                              tenant_placement
        |                              database_cluster
        |                              cell
        |
        +-- SecretsProvider ---------> restricted tenant credential
        |
        v
TenantContext(customer-a)
        |
        v
TenantRuntimeFactory
        |
        +-- TenantConnection --------> nexa_tenant_a1b2c3
                                       Espo core + Nexa business tables
```

Every browser or API request follows this sequence:

1. The gateway preserves the original hostname through a trusted, normalized server value.
2. `TrustedHostResolver` rejects malformed hosts and direct attempts to select a tenant, database or credential.
3. `TenantPlacementResolver` resolves the verified hostname through `tenant_domain` and loads the matching `tenant`, `tenant_placement`, `database_cluster` and `cell` records.
4. Routing fails closed unless every required status is active and the placement schema is compatible with the application release.
5. `SecretsProvider` resolves `credential_secret_ref`; the control database never stores the password.
6. The platform creates one immutable `TenantContext` and tenant database parameter set.
7. `TenantRuntimeFactory` initializes Espo's ORM, authentication, ACL and customer configuration against only the selected tenant database.
8. Existing Espo queries then operate normally inside that physical database boundary.
9. Logs, traces, cache keys, file prefixes, queue messages and outbox events receive tenant and request identity.
10. `TenantRuntimeScope` clears every tenant-specific service and closes or returns connections safely.

There is no fallback to a default tenant database. A missing or invalid route returns a generic not-found response; an unavailable required dependency returns a tenant-safe service-unavailable response.

### Authentication and Sessions

Tenant resolution happens before Espo authentication. The hostname determines which tenant database contains the Users, Teams, Roles and password-recovery data used for authentication. Session storage, wherever backed, is tenant-namespaced. The same email address may represent separate users in separate tenants because those records never share a database.

Password-reset, invitation and login links retain the verified tenant hostname. Session cookies are host-bound and session/cache keys include tenant identity. Platform-operator identity and audited support access remain separate from ordinary tenant users.

### Entitlements and Usage

Plans and entitlements remain in the control plane. A tenant runtime reads an immutable entitlement snapshot through an explicit `EntitlementProvider`, normally backed by a short-lived tenant-keyed cache. Product modules do not join CRM tables to `plan_entitlement`.

Control-plane changes publish an entitlement-version invalidation event. Security-critical or cost-critical actions revalidate current entitlement and quota state before execution.

Customer activity is not synchronously dual-written into `usage_counter` during every CRM transaction. The tenant transaction writes an idempotent event to its local outbox. A worker publishes that event with `tenant_id`; a control-plane consumer validates the idempotency key and updates usage counters. Analytics receives the same governed event separately.

### Background and Scheduled Jobs

A queued job contains `tenant_id`, `cell_id`, job identity, payload version and correlation identity. It never contains a raw database name, password or caller-selected credential reference.

A worker repeats the trusted runtime sequence:

1. Resolve current placement from the control plane by `tenant_id`.
2. Verify tenant and placement status.
3. Resolve the tenant credential secret.
4. Create a new `TenantContext`.
5. Boot tenant-scoped Espo services and run the job.
6. Commit tenant business changes and outbox records in the tenant database.
7. Clear the runtime scope before accepting another tenant's job.

The platform scheduler enumerates eligible tenants from the control plane and emits tenant-scoped jobs. Long-running workers must not reuse an Espo `EntityManager`, authenticated user, ACL, metadata cache, configuration overlay or database connection across tenant boundaries.

### Provisioning and Placement Changes

Provisioning is an idempotent saga rather than one cross-database transaction:

1. Create `tenant` and `provisioning_operation` as pending in `nexa_control`.
2. Select an active cell and cluster.
3. Use the cluster-administrator secret to create an opaque tenant database and restricted tenant user.
4. Store only the new `credential_secret_ref` and placement metadata in the control plane.
5. Build the canonical Espo plus Nexa tenant schema, seed reference data and create the first administrator.
6. Run login, CRUD, queue, file and backup smoke tests.
7. Mark placement and tenant active, then publish routing-cache invalidation.

A tenant move or restore creates and verifies a new database first, then atomically changes only `tenant_placement` in the control plane. Old placement remains recoverable for the approved rollback window. Requests never guess between two placements.

### Failure and Cache Rules

- Placement caches contain tenant-keyed routing metadata, never plaintext credentials.
- Cache entries have a short lifetime and a routing version; suspension, moves and credential rotation publish invalidation.
- If the control plane is unavailable, a runtime may use only a still-valid cached active route according to the approved availability policy. Without one, it fails closed.
- If one tenant database is unavailable, only that tenant fails; the application must not connect to another or a default database.
- Credential rotation changes the secret version, invalidates connection pools and forces new tenant connections.
- A job whose placement changed is resolved again before retry rather than continuing with stale database parameters.
- Logs may contain tenant and placement identifiers but never database passwords or secret values.

### Current Implementation Boundary

The current `compose.yaml` is a single-tenant development baseline. It supplies one static `ESPOCRM_DATABASE_NAME` and therefore does not yet implement runtime tenant resolution or database switching. The control-plane schema is versioned and tested separately, but the platform kernel and tenant runtime adapter described above still need to be built.

The tenancy proof of concept should use one local MariaDB service with at least three logical databases:

```text
nexa_control
nexa_tenant_alpha
nexa_tenant_beta
```

It should use a restricted control-plane runtime user plus separate restricted users for Alpha and Beta. Two local hostnames must reach the same application code, resolve through `nexa_control`, and initialize Espo against different tenant databases. The proof is complete only when authentication, core CRM CRUD, cache, files and background jobs demonstrate cross-tenant isolation.

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
