# Database Assets

Nexa uses one shared MariaDB schema for EspoCRM and Nexa-owned SaaS tables. Every tenant-owned row is scoped by a mandatory `tenant_id`; `service_id` is used only for service-owned records, entitlements, usage, audit and events.

- `shared/migrations/`: immutable shared-schema migrations applied to the EspoCRM database.
- `shared/seeds/`: synthetic plans and service definitions.
- `shared/table-ownership-manifest.json`: fail-closed table classification and Espo conversion gate.

The first migration creates the Nexa tenant, domain, plan, service, subscription, usage, provisioning, audit and outbox tables. Espo core table conversion will be delivered through reviewed expand/backfill/enforce migrations after the table-ownership and index manifest is approved.

Espo entity definitions normally belong in `espocrm/custom/` and are applied by Espo rebuild. Cross-cutting tenant columns, composite indexes, constraints and data backfills require explicit SQL migrations because they change existing core tables.

Migration files are immutable after merge. Git stores schema and synthetic fixtures only; never commit database dumps, MariaDB data files, credentials or customer data. See [Shared-Schema SaaS Data Architecture](../docs/architecture/saas-data-architecture.md).
