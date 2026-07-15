# Nexa CRM

Nexa CRM is a public, open-source project building a SaaS CRM, marketing automation and customer-engagement platform on the pinned EspoCRM 9.1.9 foundation.

The repository tracks Nexa custom code, database migrations, product requirements, architecture and development tooling. The reproducible upstream EspoCRM application tree is materialized locally after cloning and is not duplicated in Git.

## Project Status

The project is in **Phase 0: engineering and SaaS architecture baseline**. It is not production ready and must not be used to store customer data.

Read these documents before substantial development:

- [Product requirements](docs/product/feature-inventory.md)
- [Module and build roadmap](docs/product/module-build-roadmap.md)
- [SaaS architecture recommendation](docs/architecture/espocrm-saas-architecture-recommendation.md)
- [Phase 0 collaboration](docs/development/phase-0-collaboration.md)
- [Contributing](CONTRIBUTING.md)

## Pinned Baseline

| Component | Version |
|---|---|
| EspoCRM | 9.1.9 |
| PHP | 8.2.x |
| MariaDB | 10.11 |
| Docker Compose | v2 |

The project deliberately does not use `latest` tags.

## Docker Quick Start

Prerequisites: Git, PowerShell 5.1+ and Docker Desktop in Linux-container mode.

```powershell
git clone <public-repository-url>
cd espoCRM
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1
```

The setup script:

1. Creates an ignored `.env` containing random local credentials.
2. Extracts the pinned EspoCRM 9.1.9 tree from the official container image.
3. Preserves the tracked Nexa custom files.
4. Validates PHP, Git, Compose and project assets.
5. Starts MariaDB, EspoCRM and the daemon.

Open <http://localhost:8080>. The local admin username and generated password are stored in `.env`.

```powershell
docker compose ps
docker compose logs -f espocrm
docker compose down
```

`docker compose down` retains database and application files. Never add `--volumes` unless local data is intentionally being discarded.

## XAMPP Setup

XAMPP contributors use the same repository and validation rules. They need:

- PHP 8.2 with `curl`, `json`, `mbstring`, `openssl`, `pdo_mysql` and `zip`.
- MariaDB 10.11, installed separately or supplied by the project database container.
- A packaged EspoCRM 9.1.9 release archive. An upgrade archive is not a complete application.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1 `
  -ArchivePath C:\path\to\EspoCRM-9.1.9.zip `
  -SkipStart
```

Configure an Apache virtual host pointing to `espocrm/`, create the local database using the values in `.env`, then run:

```powershell
php espocrm/rebuild.php
php espocrm/clear_cache.php
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

See the [environment baseline](docs/development/environment-baseline.md) for the compatibility contract.

## Custom Development

Tracked product code belongs in:

- `espocrm/custom/` for server classes, metadata and backend modules.
- `espocrm/client/custom/` for client modules, templates, styles and assets.
- `database/` for immutable migrations and synthetic seeds.

Do not make routine changes in upstream `application/Espo/`, `client/lib/` or `client/res/`. When an upstream change is unavoidable, document it in an ADR and add bootstrap patching plus regression tests so a clean clone can reproduce it.

After custom metadata changes:

```powershell
docker compose exec espocrm php rebuild.php
docker compose exec espocrm php clear_cache.php
```

Before committing:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

## Database Collaboration

Developers never share MariaDB volumes or exchange database dumps for daily work. Every developer has independent local databases. Schema changes move through Git as custom metadata or immutable migrations; safe sample data moves as synthetic seed files.

The SaaS target uses a small shared control plane plus logical tenant databases hosted on bounded cells. See [ADR-0001](docs/architecture/ADR-0001-tenant-database-isolation.md).

## Public Repository Safety

Never commit `.env`, tokens, credentials, private keys, customer data, database dumps, attachments, cache, logs or commercial extensions. Follow [SECURITY.md](SECURITY.md) for private vulnerability reporting.

## Licence

The project is based on EspoCRM under GNU AGPLv3. See [LICENSE.md](LICENSE.md) and the retained upstream licence at [espocrm/LICENSE.txt](espocrm/LICENSE.txt). Branding and hosted-source obligations require legal review before commercial launch.
