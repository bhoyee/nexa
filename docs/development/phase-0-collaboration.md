# Phase 0 Collaboration and Database Workflow

## Objective

Both developers must be able to clone one repository, create equivalent environments, apply the same database structure, load safe development data and verify the same behavior. Docker and XAMPP are launch methods, not different architectures.

The approved technical direction should follow the [EspoCRM SaaS Architecture Recommendation](../architecture/espocrm-saas-architecture-recommendation.md).

## Version Baseline

| Component | Baseline | Notes |
|---|---|---|
| EspoCRM | 9.1.9 | Pinned; never use `latest` |
| PHP | 8.2.x initially | Match required extensions |
| MariaDB | 10.11.x | Docker declares 10.11; XAMPP's 10.4 must not define compatibility |
| Composer | 2.x | Commit lock files for Nexa-owned services |

This machine has XAMPP PHP 8.2.12 and XAMPP MariaDB 10.4.32. The XAMPP developer should run MariaDB 10.11 separately or connect Apache/PHP to the project database container. XAMPP does not require using its bundled database.

## Repository Workflow

1. Create the public GitHub repository and protect `main` with a ruleset.
2. Each developer clones it; never exchange edited folders or database files.
3. Use one short-lived branch per requirement, such as `feature/M05-contact-associations`.
4. Apply migrations and checks before opening a pull request.
5. The other developer reviews every pull request.
6. Merge only when code, migration, tests and documentation agree.

Never commit `.env`, credentials, cache, attachments, logs, generated core files or customer data.

## Local Database Layout

| Database | Purpose |
|---|---|
| `nexa_control` | Tenant registry, plans, entitlements, subscriptions and provisioning |
| `nexa_tenant_local_<developer>` | Disposable Espo tenant data owned by one developer |
| `nexa_tenant_test` | Created and destroyed by automated tests |

Developers do not share one development database server or volume. Each local server may contain the control database and disposable logical tenant databases. Git synchronizes definitions; migrations synchronize installations; seeders synchronize safe examples. Shared staging is used only after local review.

## Schema Change Rules

### Espo-Owned Entities

- Define fields, entities, relationships, indexes, layouts and scopes in Nexa custom metadata.
- Run Espo rebuild after metadata changes.
- Commit custom metadata and tests, not generated database/cache files.
- Add a tenant migration only when rebuild cannot safely transform existing data.

### Nexa-Owned Data

- Put control-plane migrations in `database/control-plane/migrations/`.
- Put exceptional tenant migrations in `database/tenant/migrations/`.
- Use immutable sortable names such as `0002_add_subscription_period.sql`.
- Never edit a migration after merge; add another migration.
- Prefer expand/migrate/contract: add, backfill, switch readers, then remove later.

### Seed Data

- Commit only synthetic, non-personal fixtures under `database/*/seeds/`.
- Never commit development or production dumps.
- Keep encrypted backups outside Git.

## Database Pull Request Checklist

- Requirement and owning module are identified.
- Migration succeeds on clean and previous schemas.
- Re-running the migration tooling is safe.
- Existing records receive valid defaults or a backfill.
- Index and query effects are reviewed.
- Tenant isolation, permissions and audit behavior are tested.
- Fixtures contain no real people, customers or credentials.
- Forward-fix and operational recovery are documented.

## Docker Developer

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose exec espocrm php rebuild.php
docker compose exec espocrm php clear_cache.php
powershell -ExecutionPolicy Bypass -File scripts/dev/check-environment.ps1
```

## XAMPP Developer

1. Clone the same repository and point an Apache virtual host to `espocrm/`.
2. Use PHP 8.2 with the same required extensions.
3. Run MariaDB 10.11 or connect PHP to the project database container.
4. Create a personal `.env` from `.env.example`.
5. Configure a developer-specific tenant database.
6. Apply the same migrations and fixtures.
7. Run `php rebuild.php`, `php clear_cache.php` and the same smoke tests.

Do not copy Docker volumes into XAMPP or exchange phpMyAdmin exports for daily synchronization.

## Phase 0 Exit Checklist

- [ ] Public Git remote exists and both developers can clone it.
- [ ] `main` is protected and review is required.
- [ ] PHP and MariaDB baselines match.
- [ ] Both developers start EspoCRM 9.1.9 from a clean checkout.
- [ ] Both developers apply an identical migration set.
- [ ] Both developers load identical synthetic fixtures.
- [ ] CI checks PHP, JSON, metadata and migration filenames.
- [ ] Clean and upgrade smoke tests cover core CRM records.
- [ ] Both developers review the cell-based SaaS data architecture and ADR.

Phase 1 starts only after this checklist is green.
