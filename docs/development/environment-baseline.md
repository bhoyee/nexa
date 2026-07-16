# Development Environment Baseline

## Pinned Components

| Component | Version | Source of truth |
|---|---|---|
| EspoCRM | 9.1.9 | `.env.example` and `compose.yaml` |
| EspoCRM container | `espocrm/espocrm:9.1.9` | `compose.yaml` |
| PHP | 8.2.x | CI and environment checker |
| MariaDB | 10.11 | `compose.yaml` and CI service |
| Docker Compose | Compose v2 | Developer tooling |
| PowerShell | 5.1+ or 7+ | Cross-Windows setup scripts |

The version baseline changes only through an architecture/release decision and a pull request that updates local setup, CI and compatibility tests together.

## Repository Versus Generated Files

Tracked:

- The complete pinned application under `espocrm/`, including backend, browser resources and runtime dependencies.
- Nexa customizations and approved changes to existing application files.
- Database migrations and synthetic seeds.
- Documentation, scripts and CI configuration.

Local and ignored:

- Runtime configuration under `espocrm/data/`.
- Cache, logs, temporary files, attachments and uploads.
- `.env`, databases and downloaded archives.

A clean clone contains the same application code and user interface for every developer. Run `scripts/dev/setup.ps1` to create local credentials, validate the complete tracked codebase and start services. Missing application files must be restored from Git or by cloning again, never from an upstream package.

## Required PHP Extensions

- `curl`
- `json`
- `mbstring`
- `openssl`
- `pdo_mysql`
- `zip`

Docker, XAMPP and WampServer contributors run the same repository checks. XAMPP or WampServer may provide Apache/PHP, but PHP must remain 8.2.x and MariaDB behavior must match 10.11.
