# Release Process

Nexa uses Semantic Versioning independently of the imported application baseline. The repository `VERSION` file is the single source of truth for the next release identifier.

## Version Format

- Development prerelease: `0.1.0-dev.1`
- Feature release: `0.1.0`
- Compatible fixes: `0.1.1`
- First general-availability release: `1.0.0`

The existing `nexa-codebase-9.1.9` tag records the application import baseline. It is not a Nexa product release.

## Prepare A Release

1. Create an assigned release issue and a short-lived branch from `main`.
2. Update `VERSION` without a leading `v`.
3. Move completed entries from `Unreleased` into a dated section in `CHANGELOG.md`.
4. Include database migrations, configuration changes, known risks and rollback guidance.
5. Open a pull request and obtain the required review.
6. Merge only after all required checks pass.
7. Pull the merged `main` branch and create an annotated tag matching `v` plus `VERSION`.

```powershell
git switch main
git pull --ff-only
$version = (Get-Content VERSION -Raw).Trim()
git tag -a "v$version" -m "Nexa v$version"
git push origin "v$version"
```

Pushing a matching tag runs `.github/workflows/release.yml`. The workflow verifies the version, confirms the tagged commit belongs to `main`, runs repository validation and publishes a GitHub Release. Versions containing a hyphen are published as prereleases.

Published release tags are immutable. Correct a bad release with a new patch or prerelease version instead of moving or replacing its tag.

The current organisation settings and prerelease evidence are recorded in [Phase 0 Repository and Release Verification](phase-0-release-verification.md).

## Tag Ruleset

Configure a GitHub tag ruleset targeting `v*` that blocks tag updates and deletion. Limit bypass permission to the repository owner. The application-baseline tag remains outside this product-release pattern.
