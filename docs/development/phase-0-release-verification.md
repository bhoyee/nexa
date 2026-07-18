# Phase 0 Repository and Release Verification

Verified against `NaxoCRM-Team/nexa` on 18 July 2026. No token, credential or machine-specific path is recorded here.

## Enforced Repository Controls

- `Protect main` ruleset `19014050` is active for the default branch.
- Pull requests are required and branches must be current with `main`.
- Required checks are Repository and source validation, Shared-schema SaaS foundation, and Shell accessibility and visual validation.
- Branch deletion, force pushes and non-linear history are blocked.
- CODEOWNERS provides review routing; an approval is not a merge blocker for the current core team.
- `Protect release tags` ruleset `19040086` blocks deletion and updates for `v*` tags.
- Secret scanning, push protection, Dependabot alerts and automated security updates are enabled.

## Release Evidence

The first Nexa prerelease uses `VERSION` value `0.1.0-dev.1` and immutable tag `v0.1.0-dev.1`. The release workflow validates that the tag matches `VERSION`, belongs to `main`, passes repository and Compose checks, and publishes a GitHub prerelease with generated source archives. The workflow run and release URL are recorded on issue #13 after the protected merge and tag operation.

## Phase 0 Gate

Clean Docker and native Windows setup, shared-schema parity, migration idempotency, two-tenant fixtures, runtime isolation, CRM CRUD smoke tests and credential scanning are automated. Local runtime credentials and database data remain ignored. Failures are diagnosed through the named CI job, migration record and application log without printing secrets.
