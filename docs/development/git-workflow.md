# Git and GitHub Workflow

## Public Repository Model

The repository is public for transparency and collaboration. Public visibility does not make `main` an unrestricted integration branch. All product changes use issues, short-lived branches, pull requests, automated checks and peer review.

## Initial GitHub Settings

After creating the public repository:

1. Add it as `origin` and push `main`.
2. Enable Issues, Discussions and private vulnerability reporting.
3. Enable secret scanning and push protection.
4. Create a `main` ruleset requiring pull requests.
5. Require one approval and dismissal of stale approvals.
6. Require the `Repository and source validation` and `Control-plane schema` checks.
7. Require conversation resolution and block force pushes and deletion.
8. Allow only maintainers to bypass the ruleset for emergencies.
9. Add both core developers with Maintain access.
10. Add `CODEOWNERS` after both GitHub usernames are known.

## Daily Flow

```powershell
git switch main
git pull --ff-only
git switch -c feature/M05-short-description

# Work, test and commit.
powershell -ExecutionPolicy Bypass -File scripts/dev/verify.ps1
git add <intentional-files>
git commit -m "feat(M05): describe the behavior"
git push -u origin feature/M05-short-description
```

Open a pull request, complete its checklist and request review from the other core developer.

## Commit Format

Use `type(scope): summary`:

- `feat(M10): add email approval metadata`
- `fix(auth): preserve login return route`
- `docs(architecture): record tenant placement decision`
- `chore(ci): validate migration seeds`

Recommended types are `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci` and `chore`.

## Merge and Release

- Use squash merge for ordinary pull requests.
- Keep `main` deployable.
- Tag releases as `v0.x.y` during development and `v1.0.0` at general availability.
- Release notes list migrations, configuration changes, known risks and rollback guidance.
- Never rewrite published release tags.

## Database Conflicts

Do not resolve competing migrations by editing a migration already merged to `main`. Rebase, retain both immutable files and add a later corrective migration when ordering or behavior requires it.
