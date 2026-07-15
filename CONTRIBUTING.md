# Nexa Development Workflow

This workflow is for designated Nexa team members and explicitly invited collaborators. The project is not currently accepting unsolicited implementation contributions or feature pull requests.

## Before Starting Work

1. Confirm that a project issue and requirement ID exist.
2. Read the [Git Workflow](docs/development/git-workflow.md).
3. Review relevant architecture decisions and module ownership.
4. Run `powershell -ExecutionPolicy Bypass -File scripts/dev/setup.ps1` after cloning.

## Branches

Create a short-lived branch from `main`:

- `feature/M05-contact-associations`
- `fix/login-redirect`
- `docs/database-migrations`
- `chore/ci-json-validation`

Do not push feature work directly to `main`.

## Pull Requests

- Keep one coherent change per pull request.
- Reference the requirement ID and assigned issue.
- Include migrations and synthetic fixtures when data structures change.
- Add or update automated tests.
- Include desktop and mobile evidence for visual changes.
- Update architecture or operational documentation when contracts change.
- Run `scripts/dev/verify.ps1` before requesting review.
- Obtain review from the other core developer.

## Repository Safety

Never commit:

- `.env` files or credentials.
- API keys, OAuth tokens, cookies or private keys.
- Customer, production or personal data.
- Database dumps, database volumes or backups.
- Runtime cache, logs, attachments or exports.
- Commercial third-party extensions.
- Generated application files outside approved tracked paths.

Use invented data in tests and examples. Report security issues according to [SECURITY.md](SECURITY.md), not through a public issue.

## Database Changes

- Prefer supported application metadata for entities and fields.
- Use immutable SQL migrations for transformations and Nexa-owned schemas.
- Never modify an already merged migration.
- Test clean installation and upgrade from the previous schema.
- Document backfill, index, recovery and tenant-isolation effects.

## Definition of Done

The project-wide definition of done is maintained in the [Module and Build Roadmap](docs/product/module-build-roadmap.md). A feature is not complete merely because it works on one developer's database.
