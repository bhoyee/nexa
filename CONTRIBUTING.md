# Contributing to Nexa CRM

Thank you for helping build Nexa CRM. This repository is public, but changes are accepted through reviewed pull requests only.

## Before You Start

1. Read [Phase 0 Collaboration](docs/development/phase-0-collaboration.md).
2. Read the [Git Workflow](docs/development/git-workflow.md).
3. Read the [SaaS Architecture Recommendation](docs/architecture/espocrm-saas-architecture-recommendation.md).
4. Run `powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1` from a clean clone.
5. Choose or create a GitHub issue before beginning substantial work.

## Branches

Create short-lived branches from `main`:

- `feature/M05-contact-associations`
- `fix/login-redirect`
- `docs/database-migrations`
- `chore/ci-json-validation`

Do not push feature work directly to `main`.

## Pull Requests

- Keep one coherent change per pull request.
- Reference the requirement ID and GitHub issue.
- Include migrations and synthetic fixtures when data structures change.
- Add or update automated tests.
- Include desktop and mobile evidence for visual changes.
- Update architecture or operational documentation when contracts change.
- Run `scripts/dev/verify.ps1` before requesting review.
- Obtain review from the other core developer.

## Public Repository Safety

Never commit:

- `.env` files or credentials.
- API keys, OAuth tokens, cookies or private keys.
- Customer, production or personal data.
- Database dumps, MariaDB volumes or backups.
- Runtime cache, logs, attachments or exports.
- Licensed commercial EspoCRM extensions.
- Generated upstream application files outside the allowed custom paths.

Use invented data in tests and examples. Report security issues according to [SECURITY.md](SECURITY.md), not through a public issue.

## Database Changes

- Prefer Espo custom metadata for Espo entities and fields.
- Use immutable SQL migrations for transformations and Nexa-owned schemas.
- Never modify an already merged migration.
- Test clean installation and upgrade from the previous schema.
- Document backfill, index, recovery and tenant-isolation effects.

## Definition of Done

The project-wide definition of done is maintained in the [Module and Build Roadmap](docs/product/module-build-roadmap.md). A feature is not complete merely because it works on one developer's database.
