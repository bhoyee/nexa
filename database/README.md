# Database Assets

This directory contains version-controlled Nexa database definitions. It never contains dumps, MariaDB data files, credentials or customer data.

- `control-plane/migrations/`: shared SaaS control-plane schema.
- `control-plane/seeds/`: synthetic plans and feature keys.
- `tenant/migrations/`: exceptional changes not safely expressible in Espo metadata.
- `tenant/seeds/`: synthetic CRM fixtures.

Espo entity definitions normally belong in `espocrm/custom/` and are applied by Espo rebuild. Migration files are immutable after merge; future tooling will record every filename and checksum.

The control plane and tenant databases are logical databases. A MariaDB cluster may host many tenant databases, but each tenant database contains both Espo core and all Nexa business modules for exactly one customer. See [SaaS Data Architecture](../docs/architecture/saas-data-architecture.md).
