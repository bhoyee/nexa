# Delivery Management

## Planning Workspace

[Nexa Product Delivery](https://github.com/orgs/NaxoCRM-Team/projects/1) is the internal planning workspace for product and engineering delivery. GitHub Issues are the canonical backlog; the roadmap documents define strategy and dependency order but do not replace issue tracking.

The Project is private to the organization. The public repository does not make internal planning data public.

## Planning Hierarchy

```text
Release
  -> Phase milestone
    -> Module
      -> Issue or user story
        -> Sub-issue or technical task
          -> Pull request
```

- Releases group customer-facing outcomes from R0 through R6.
- Phase milestones are dependency and exit gates from Phase 0 through Phase 12.
- Modules M01 through M23 define architecture and ownership boundaries.
- Sprint iterations are two-week delivery commitments.
- Pull requests close scoped issues after review and required CI.

## Project Fields

| Field | Purpose |
|---|---|
| Status | Backlog, Ready, In Progress, In Review, Blocked or Done |
| Milestone | Phase gate maintained by the repository |
| Sprint | Two-week iteration beginning with Sprint 01 on 20 July 2026 |
| Module | Owning module from M01 through M23 |
| Priority | P0 Critical, P1 High, P2 Normal or P3 Low |
| Workstream | Platform, Product or Shared |
| Size | XS, S, M or L; split L items before sprint commitment |
| Release | R0 Engineering Baseline through R6 SaaS General Availability |
| Start date | Planned start for roadmap display |
| Target date | Planned completion for roadmap display |

## Required Views

Maintain these Project views:

1. Current Sprint: board layout, filter to the current Sprint and group by Status.
2. Product Backlog: table layout, exclude Done and group by Milestone then Module.
3. Roadmap: roadmap layout using Start date and Target date, grouped by Release.
4. Platform Work: table or board filtered to Workstream = Platform or Shared.
5. Product Work: table or board filtered to Workstream = Product or Shared.
6. My Work: table filtered to the current viewer and excluding Done.

GitHub currently requires view layout and saved-view configuration through the Project interface. Project fields, iterations and backlog data are managed through the organization Project.

## Labels

Labels describe repository-level classification that is useful outside the Project:

- `type:*`: bug, feature, technical, NFR or documentation.
- `area:*`: frontend, backend, database, security, infrastructure, integration, automation or analytics.
- `status:blocked`: an external dependency prevents progress.
- `status:needs-decision`: an architecture or product decision is required.
- `duplicate`, `invalid`, `question` and `wontfix`: issue-triage outcomes.

Priority and Workstream are Project fields, not labels. Phase is a milestone, and Sprint is an iteration.

## Sprint Cadence

Sprints run for two weeks. During planning:

1. Confirm the sprint goal and available capacity.
2. Select only Ready issues from the active phase.
3. Assign an owner, module, priority, workstream, size, release and sprint.
4. Split any item that cannot satisfy the Definition of Done inside the sprint.
5. Limit each developer to one major In Progress issue at a time.

During delivery, move work from Ready to In Progress and then In Review when its pull request opens. Move it to Done only after required checks, review, documentation and acceptance evidence are complete.

At sprint close, review completed outcomes, return unfinished work to Ready or deliberately schedule it, and record process improvements. Do not silently carry incomplete work into the next sprint.

## Issue Readiness

An issue is Ready only when it has:

- a clear objective and testable acceptance criteria;
- a phase milestone, module, priority, workstream, size and release;
- identified dependencies and tenant/security implications;
- database, responsive UI and documentation expectations where applicable;
- an assignee with enough capacity to complete it.

Every implementation branch references its issue, and every pull request uses `Closes #<issue>` when the change completes that issue.