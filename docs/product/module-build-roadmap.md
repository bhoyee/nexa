# Nexa CRM Module and Build Roadmap

## Product Direction

Nexa CRM will use EspoCRM 9.1.9 as its CRM foundation, but the finished product will have its own design system, navigation, terminology, modules, SaaS controls and operating model. It will not embed or merge the Mautic codebase. Marketing and automation capabilities will be implemented as Nexa-owned modules or connected providers.

"Customize everything" means that every relevant workflow and user-facing surface is deliberately reviewed, branded and tested. It does **not** mean editing every upstream EspoCRM source file. Keep the pinned EspoCRM tree as the foundation and implement product behavior through `custom/`, `client/custom/`, metadata, extension packages, APIs and separately deployed services. A core-file change requires an architecture decision record, an automated regression test and a documented reason that no extension point can satisfy the requirement.

## Architecture Layers

| Layer | Responsibility | Deployment boundary |
|---|---|---|
| Nexa experience | Application shell, navigation, design system, responsive layouts and branded workflows | Espo client custom modules |
| Business modules | CRM, marketing, automation, service, conversations and administration | Espo custom PHP and client modules |
| SaaS control plane | Tenants, plans, entitlements, metering, billing, provisioning and operator console | Separate Nexa service and worker |
| Data and event platform | Event collection, queues, search, reporting models and audit data | Workers and supporting data stores |
| Provider adapters | Email, SMS, WhatsApp, social, ads, identity, AI and analytics integrations | Versioned adapters behind Nexa interfaces |
| Operations | CI/CD, secrets, monitoring, backups, security and incident tooling | Shared platform infrastructure |

## Ordered Module Catalogue

The order below is the dependency order, not the menu order. Modules with lower order numbers establish contracts used by later modules.

| Order | Module | Scope | Functional requirements |
|---|---|---|---|
| M01 | Nexa Platform Core | Module conventions, configuration, feature flags, audit events, API conventions, queues, shared errors and extension packaging | F-003 |
| M02 | Nexa Design System and App Shell | Brand, login, global navigation, search, notifications, responsive layouts, accessibility, interface configuration and reusable UI components | F-002, F-012, F-059 |
| M03 | SaaS Control Plane | Tenant lifecycle, plans, entitlements, quotas, metering, billing integration, tenant branding, domains and sandbox accounts | F-001, F-005, F-014, F-035, F-038, F-077 |
| M04 | Identity, Teams and Access | Users, social login, SSO, MFA hooks, permission sets, teams, hierarchy, field/content restrictions, sensitive-data protection and audited impersonation | F-015, F-024, F-067, F-072, F-073, F-074, F-079, F-083 |
| M05 | CRM Data Platform | Accounts, contacts, leads, opportunities, custom objects, fields, associations, calculated properties, currencies, import/export and deduplication | F-026, F-029, F-039, F-040, F-047, F-068 |
| M06 | Sales Workspace | Pipeline, lead and deal workspaces, activities, tasks, calendar, documents, collaboration and account-centered workflows | F-050 |
| M07 | Service and Knowledge | Cases, customer service workspace, knowledge base, portals, team email and support entitlements | F-020, F-027, F-028 |
| M08 | Consent, Forms and Content | Consent ledger, cookie tools, forms, form actions, landing/content metadata, URL mappings, localization and video assets | F-010, F-016, F-032, F-034, F-042 |
| M09 | Marketing Contacts and Campaigns | Marketing-contact status, audiences, target lists, segmentation, campaigns, marketing events, presets and asset governance | F-007, F-044, F-055 |
| M10 | Marketing Email and Deliverability | Email editor, templates, personalization, programmable/single-send APIs, approvals, sending domains, suppression and health reporting | F-013, F-025, F-031, F-033, F-071, F-075, F-085 |
| M11 | Tracking and Event Platform | Web tracking, identity resolution, logged-in visitor identification, custom/behavioral events, reply tracking and visual event configuration | F-021, F-022, F-053, F-066, F-070, F-082 |
| M12 | Automation Engine | Trigger/action workflows, delays, branching, enrollment, retries, versioning, omnichannel orchestration and simple ad automation | F-004, F-009, F-030, F-037 |
| M13 | Scoring, Personalization and ABM | Contact/deal/company scoring, target accounts, ABM orchestration and dynamic content decisions | F-045, F-049, F-051, F-056, F-061, F-065 |
| M14 | Conversations and Bots | Shared inbox, live chat widget, Messenger, bots, custom inbox views and draggable widget configuration | F-008, F-011, F-018, F-036, F-063 |
| M15 | Messaging Channels | SMS and WhatsApp consent, templates, sending, replies, provider callbacks and automation actions | F-046, F-048 |
| M16 | Social Workspace | Social accounts, publishing, scheduling, inbox, approvals, listening and platform policy enforcement | F-006 |
| M17 | Advertising | Ad account connections, audiences, campaign visibility, retargeting and conversion events | F-017, F-023, F-064 |
| M18 | SEO and Content Intelligence | SEO recommendations, page/search performance, Search Console data and YouTube analytics | F-019, F-058, F-062, F-086 |
| M19 | Analytics, Reporting and Attribution | Custom reports, filtered views, campaign and asset comparison, attribution, journeys and governed analytics models | F-043, F-054, F-060, F-069, F-081 |
| M20 | Enterprise Integrations | Connector framework, OAuth/credential lifecycle, Salesforce record and custom-object synchronization | F-057, F-078 |
| M21 | AI Services | Provider-neutral AI gateway, Anthropic adapter, social agent and social-inbox insights with safety and usage controls | F-052, F-080, F-084 |
| M22 | Administration and Support Operations | Tenant/operator settings, notifications, support console, audit access, health, usage and operational controls | F-076 |
| M23 | Experimentation | Audience assignment, A/B variants, statistical results and winner selection for email and content | F-041 |

All 86 functional IDs are assigned. The Additional features requirement remains a controlled discovery bucket in M01 and must be split into testable requirements before scheduling.

## Existing EspoCRM Coverage

Every existing area receives a product decision: retain and redesign, extend, replace behind the same user workflow, or retire. Nothing should disappear accidentally.

| Existing area | Nexa treatment | Owning module |
|---|---|---|
| Login, password recovery and authentication | Rebuild as Nexa responsive authentication experience; connect SSO and social identity later | M02, M04 |
| Home, dashboards, navbar, search and notifications | Replace the visual shell and information architecture; preserve supported extension contracts | M02 |
| Accounts, Contacts and Leads | Retain data foundations; redesign record, list, create, merge and relationship workflows | M05 |
| Opportunities | Retain core model; redesign pipeline, forecasting-ready fields and account context | M05, M06 |
| Tasks, Calls, Meetings, Calendar and reminders | Unify into the Sales Workspace and responsive activity composer | M06 |
| Emails, email accounts, templates and inbound email | Separate personal/team email from marketing email; share governed contact and consent data | M07, M10 |
| Cases, Knowledge Base and Portal | Redesign as Service workspace with tenant-aware support entitlements | M07 |
| Campaigns, Target Lists and Mass Email | Reuse suitable records and replace limited workflows with Nexa campaign and email modules | M09, M10 |
| Documents, attachments, notes and stream | Retain storage concepts; apply tenant isolation, permissions, collaboration UI and lifecycle rules | M05, M06 |
| Users, Teams, Roles and Portals | Extend for plan limits, reusable permissions, hierarchy, field security and tenant boundaries | M03, M04 |
| Imports, exports and duplicate checking | Turn into governed, asynchronous data operations with validation and auditability | M05 |
| Administration, entity manager, layouts and settings | Reorganize into tenant administration and operator-only administration | M02, M22 |
| Jobs, scheduled jobs, webhooks and integrations | Wrap with tenant context, idempotency, observability, retries and provider adapters | M01, M20, M22 |
| API | Keep compatible endpoints where useful; add tenant-aware, versioned Nexa APIs and event contracts | M01, M20 |

## Build Phases

### Phase 0 - Product and Engineering Baseline

**Goal:** Make two-developer work reproducible before feature development.

The working agreement and exit checklist are maintained in [Phase 0 Collaboration and Database Workflow](../development/phase-0-collaboration.md). The tenant isolation decision is recorded in [ADR-0001](../architecture/ADR-0001-tenant-database-isolation.md) and detailed in the [SaaS Data Architecture](../architecture/saas-data-architecture.md).

- Agree Git workflow, protected main branch, issue template, definition of done and ownership.
- Make Docker and XAMPP use the same PHP version, extensions, database version, configuration and seed process.
- Create sanitized fixtures; never share live database files or credentials.
- Establish architecture decisions, coding standards, automated formatting and CI checks.
- Baseline EspoCRM 9.1.9 behavior and record permitted extension points.
- Convert requirements into acceptance criteria and Launch/Growth/Scale entitlements.

**Exit gate:** Both developers can create the same clean environment, run the same smoke tests and load the same seed data.

### Phase 1 - Platform Core and Complete Visual Foundation

**Modules:** M01, M02

- Establish Nexa module namespaces and packaging conventions.
- Build design tokens, typography, controls, tables, forms, modals, empty/error states and responsive patterns.
- Redesign login, application shell, main navigation, global search, dashboards and common record/list views.
- Add feature flags, shared audit-event API, error contracts and background-job conventions.
- Inventory every Espo screen and give it an explicit retain/redesign/extend/retire status.

**Exit gate:** Nexa no longer feels like a renamed login page; common desktop and mobile workflows consistently use the Nexa shell.

### Phase 2 - SaaS, Identity and Security Foundation

**Modules:** M03, M04, M22 foundation

- Implement tenant identity and isolation rules before adding customer data.
- Add provisioning, plan entitlements, quotas, usage events and billing-provider boundary.
- Add tenant admin versus platform operator roles.
- Deliver permission sets, teams, hierarchy, SSO hooks, field restrictions and audited impersonation.
- Establish secrets, encryption, audit logging, retention and tenant export/deletion workflows.

**Exit gate:** Automated tests prove that one tenant cannot read, change, search, export or process another tenant's data.

### Phase 3 - CRM, Sales and Service Product

**Modules:** M05, M06, M07

- Redesign and harden Accounts, Contacts, Leads, Opportunities and activities.
- Add association labels, calculated properties, required fields, custom objects and duplicate management.
- Complete sales pipeline, tasks, documents, collaboration and multi-currency behavior.
- Complete Cases, Knowledge Base, Portal, team email and support workflows.
- Deliver governed import/export and migration tooling.

**Exit gate:** A tenant can operate the full CRM, sales and service lifecycle without using legacy-looking or cross-tenant administration paths.

### Phase 4 - Marketing Data, Consent and Campaign Foundation

**Modules:** M08, M09

- Add marketing-contact classification, consent history, cookie preferences and suppression state.
- Build forms, field mapping, validation and form-triggered actions.
- Build segmentation, audiences, campaign membership and marketing event records.
- Add content localization, URL mappings, asset storage and reusable presets.

**Exit gate:** Campaign audiences are reproducible, consent-aware and explainable before any bulk send is allowed.

### Phase 5 - Marketing Email and Deliverability

**Modules:** M10, then M23 email experiments

- Build the editor, templates, personalization tokens, smart content and programmable email.
- Add approvals, test sends, scheduling, plan limits and single-send API.
- Implement sending-domain verification, SPF/DKIM/DMARC guidance, bounce/complaint callbacks and suppression enforcement.
- Add deliverability and email-health reporting.
- Add email A/B testing only after deterministic sending and tracking are proven.

**Exit gate:** End-to-end test campaigns can be safely composed, approved, sent, tracked, unsubscribed and reconciled without duplicate delivery.

### Phase 6 - Tracking, Events and Automation

**Modules:** M11, M12

- Introduce a versioned behavioral-event schema and collection API.
- Build anonymous and known visitor identity resolution with consent controls.
- Add custom events, reply tracking, visual event configuration and event retention.
- Build versioned workflow definitions, enrollment, branches, delays, actions, retries, cancellation and history.
- Add email, form and omnichannel automation with tenant fairness and safety limits.

**Exit gate:** Events and workflows are idempotent, replayable, observable and cannot cross tenant boundaries.

### Phase 7 - Scoring, Personalization and ABM

**Modules:** M13

- Build explainable contact, company and deal scoring models.
- Create target-account workspace, ABM lists and account-based automation.
- Add dynamic personalization backed by deterministic rules before AI-generated decisions.
- Enforce plan limits on scoring models and advanced ABM features.

**Exit gate:** Users can explain why a score or personalization decision occurred and reproduce it from stored inputs.

### Phase 8 - Conversations and Omnichannel Messaging

**Modules:** M14, M15

- Build shared inbox, assignment, views, live chat and draggable widget controls.
- Add conversational bot definitions and safe handoff to staff.
- Add Messenger, SMS and WhatsApp through provider adapters.
- Reuse contact identity, consent, suppression, automation and audit services.

**Exit gate:** One conversation timeline supports channel replies, consent enforcement, assignment and failure recovery.

### Phase 9 - Analytics, Attribution and Customer Journeys

**Modules:** M19

- Establish governed reporting models separated from transactional CRM queries.
- Build custom reports, filtered views, campaign comparison and funnel reporting.
- Add contact-create and multi-touch attribution with documented attribution models.
- Add customer journey analytics and explainable event paths.

**Exit gate:** Report figures reconcile to source records and remain stable under documented attribution definitions.

### Phase 10 - Social, Advertising, SEO and Content Intelligence

**Modules:** M16, M17, M18, remaining M23 experiments

- Add social account authorization, publishing, scheduling, inbox and platform-policy controls.
- Add ad accounts, audiences, retargeting and conversion-event synchronization.
- Add SEO recommendations, Search Console data, SEO analytics and YouTube analytics.
- Expand A/B testing to supported marketing content.

**Exit gate:** Each provider adapter has contract tests, token recovery, rate-limit handling, audit trails and graceful degradation.

### Phase 11 - Enterprise Integrations and AI

**Modules:** M20, M21

- Build connector mapping, conflict resolution, reconciliation and failure queues.
- Add Salesforce standard and custom-object synchronization.
- Build a provider-neutral AI gateway with usage metering, redaction, prompt/version audit and human approval controls.
- Add Anthropic, social agent and social-inbox insight capabilities through the gateway.

**Exit gate:** External sync and AI failures cannot corrupt CRM records, leak tenant data or create unbounded cost.

### Phase 12 - Production Hardening and SaaS Launch

**Modules:** All modules and all NFRs

- Complete load, accessibility, security, tenant-isolation, disaster-recovery and upgrade tests.
- Validate backups and per-tenant restoration; exercise incident and provider-outage runbooks.
- Complete billing reconciliation, usage dashboards, support console and service-status processes.
- Complete licensing review, SBOM, privacy documents, retention policies and operational ownership.
- Run internal alpha, design-partner beta and controlled production rollout.

**Exit gate:** Every Launch requirement has acceptance evidence, an owner, monitoring, support documentation and a rollback path.

## Recommended Release Slices

| Release | Included phases | Product outcome |
|---|---|---|
| R0 Engineering baseline | Phase 0 | Two developers can work safely and reproducibly |
| R1 Nexa CRM Alpha | Phases 1-3 | Branded, tenant-aware CRM, sales and service product |
| R2 Marketing MVP | Phases 4-6 | Consent-aware campaigns, email, tracking and automation |
| R3 Growth Suite | Phases 7-9 | Scoring, ABM, conversations and trustworthy analytics |
| R4 Channel Suite | Phase 10 | Social, ads, SEO and content experiments |
| R5 Enterprise Beta | Phase 11 | Salesforce and governed AI capabilities |
| R6 SaaS General Availability | Phase 12 | Hardened production SaaS with operational evidence |

Do not try to build all phases concurrently. For a two-person team, maintain one platform stream and one product stream, but finish each phase's shared contracts before starting dependent modules.

## Two-Developer Ownership Model

| Stream | Primary focus | Shared responsibility |
|---|---|---|
| Platform developer | M01, M03, M04, M11 infrastructure, M20, M22, CI/CD and NFRs | Data contracts, security review and releases |
| Product developer | M02, M05-M10, M12-M19, M21 and M23 user workflows | Acceptance criteria, responsive UI and regression tests |

Ownership is not exclusivity. Every pull request should be reviewed by the other developer. Rotate ownership periodically so neither the SaaS platform nor the product UI becomes single-person knowledge.

## Mandatory Definition of Done

A module or feature is not complete until it has:

1. Approved acceptance criteria and plan entitlement.
2. Tenant isolation and permission tests.
3. Desktop and mobile UX using the Nexa design system.
4. Accessibility and localization consideration.
5. Automated unit, integration and relevant end-to-end tests.
6. Audit events, metrics, logs and actionable failure states.
7. Migration, seed data, rollback and upgrade behavior.
8. API and data-dictionary documentation where applicable.
9. Security, privacy, retention and provider-cost review.
10. Product-owner acceptance and peer code review.

## Immediate Backlog

1. Finish Phase 0 environment parity and Git/CI workflow.
2. Create the screen inventory for all existing EspoCRM routes and admin pages.
3. Define Nexa design tokens and application navigation before redesigning individual modules.
4. Specify tenant isolation architecture and decide database tenancy strategy.
5. Add acceptance criteria, source strategy and release assignment to `feature-inventory.md`.
6. Deliver R1 before beginning marketing-email or automation implementation.
