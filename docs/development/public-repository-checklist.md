# Public Repository Launch Checklist

## Local Baseline

- [x] Git repository initialized on `main`.
- [x] Environment secrets and runtime data ignored.
- [x] Public contribution, conduct, support and security policies added.
- [x] Issue and pull-request templates added.
- [x] CI validates source, metadata, Compose and shared-schema SaaS SQL.
- [x] Environment and database baselines documented.
- [x] Fresh-clone bootstrap and verification scripts added.
- [ ] Fresh clone tested in a separate directory.
- [ ] Initial commit created and reviewed.

## GitHub Configuration

- [ ] Public GitHub repository created.
- [ ] `origin` remote added and `main` pushed.
- [ ] Both core developers added with Maintain access.
- [ ] Issues and Discussions enabled.
- [ ] Private vulnerability reporting enabled.
- [ ] Secret scanning and push protection enabled.
- [ ] `main` ruleset configured according to `git-workflow.md`.
- [ ] Both CI checks required.
- [ ] `CODEOWNERS` added with real GitHub usernames.
- [ ] Repository description, topics and website set.

## Second-Developer Acceptance

- [ ] Second developer clones the public repository rather than receiving a folder.
- [ ] Setup creates a personal `.env` without exposing credentials.
- [ ] Clone contains the complete pinned application and committed Nexa interface.
- [ ] Docker, XAMPP or WampServer reaches the login page.
- [ ] Environment and repository verification passes.
- [ ] Database version and schema match the baseline.
- [ ] Developer creates a test branch and opens a pull request.

Do not declare Phase 0 complete until the second-developer acceptance path succeeds from a clean clone.
