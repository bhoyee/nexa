# Nexa

Nexa is a unified customer platform for CRM, sales, marketing automation, customer engagement and analytics.

This repository supports development by the designated Nexa project team. The team is not currently accepting unsolicited feature contributions, implementation pull requests or public support requests.

## Product Areas

- Customer and company relationship management
- Sales pipelines and team productivity
- Marketing campaigns and automation
- Email, messaging and customer conversations
- Reporting, attribution and customer analytics
- SaaS administration, plans and tenant operations

## Development Baseline

| Component | Version |
|---|---|
| Application release | 9.1.9 |
| PHP | 8.2.x |
| MariaDB | 10.11 |
| Docker Compose | v2 |

Changes to the baseline require an approved pull request that updates local setup, CI and compatibility checks together.

## Docker Setup

Prerequisites: Git, PowerShell 5.1+ and Docker Desktop in Linux-container mode.

```powershell
git clone https://github.com/bhoyee/nexa.git
cd nexa
powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1
```

The setup command creates ignored local credentials, materializes the pinned application source, validates the environment and starts the application services.

Open <http://localhost:8080>. Local administrator credentials are stored in the ignored `.env` file.

```powershell
docker compose ps
docker compose logs -f espocrm
docker compose down
```

`docker compose down` retains local application and database data. Do not add `--volumes` unless the local environment is intentionally being discarded.

## XAMPP Setup

Designated team members using XAMPP should follow the [development environment baseline](docs/development/environment-baseline.md). Docker and XAMPP contributors use the same source, schema migrations, synthetic fixtures and verification checks.

## Team Workflow

1. Select or create an assigned issue.
2. Create a short-lived branch from `main`.
3. Make the scoped code, metadata, migration, test and documentation changes.
4. Run the repository verification command.
5. Open a pull request for review by the other core developer.
6. Merge only after required checks and review pass.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
```

The detailed workflow is maintained in [Git and GitHub Workflow](docs/development/git-workflow.md).

## Development Boundaries

- Server customizations belong under `espocrm/custom/`.
- Browser customizations belong under `espocrm/client/custom/`.
- Immutable database migrations and synthetic seeds belong under `database/`.
- Architecture and product decisions belong under `docs/`.
- Credentials, customer data, runtime files, database dumps and commercial extensions must never be committed.

Developers maintain independent local databases. Database structure moves through Git as metadata and migrations; approved synthetic data moves through seed files.

## Security

Do not publish credentials, tokens, private keys, personal data or vulnerability details. Follow [SECURITY.md](SECURITY.md) for private vulnerability reporting.

## Licences and Notices

Applicable third-party and upstream licence notices are retained in [LICENSE.md](LICENSE.md) and component source files. Repository visibility does not grant trademark rights or replace the obligations of those licences.
