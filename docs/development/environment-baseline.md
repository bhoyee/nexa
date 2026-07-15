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

- Nexa server customizations under `espocrm/custom/`.
- Nexa browser customizations under `espocrm/client/custom/`.
- Database migrations and synthetic seeds.
- Documentation, scripts and CI configuration.

Generated locally:

- The remaining pinned EspoCRM application tree.
- Runtime configuration, cache, logs and attachments.
- `.env`, databases and downloaded archives.

Run `scripts/dev/setup.ps1` after cloning. It materializes the pinned upstream tree without committing generated or runtime files.

## Required PHP Extensions

- `curl`
- `json`
- `mbstring`
- `openssl`
- `pdo_mysql`
- `zip`

Both Docker and XAMPP contributors run the same repository checks. XAMPP may provide Apache/PHP, but MariaDB behavior must match 10.11.
