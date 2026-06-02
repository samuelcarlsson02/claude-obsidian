---
type: entity
title: "GrantMe"
created: 2026-06-01
updated: 2026-06-01
address: c-000004
tags:
  - entity
  - product
  - saas
  - dotnet
  - react
status: developing
entity_type: product
role: "Multi-tenant grant management SaaS for Swedish foundations"
first_mentioned: "[[GrantMe Claude Code Configuration]]"
related:
  - "[[GrantMe Claude Code Configuration]]"
  - "[[Claude Code Project Configuration]]"
  - "[[Plan-Implement-Review Agent Workflow]]"
  - "[[Claude Code Agent Memory Pattern]]"
---

# GrantMe

A multi-tenant grant management SaaS platform for Swedish foundations and organizations, built by **LogicInjection** (Azure DevOps org `logicinjection`). It manages the full grant lifecycle: application periods, application intake, reviewer scoring, approval/decline decisions, payments, document signing, and reporting. Localized for Sweden: Swedish UI default, BankID authentication, SEK currency, Bankgiro/Plusgiro payments.

**Organisation** is the tenant entity. All data is scoped to an `OrganisationId`, extracted from the route and validated against the user's membership.

## Tech Stack

| Layer | Stack |
|---|---|
| Backend | .NET 9, C# (nullable enabled), ASP.NET Core Web API, EF Core, SQL Server |
| Frontend | React 18 + TypeScript + Mantine v8; admin/client on Vite + Vitest, www on CRA + Jest |
| Auth | Azure AD B2C via MSAL (admin + client); separate AAD scheme for the management portal |
| Background | Azure Functions (queues, Service Bus, timers) |
| Integrations | Azure Blob Storage, Service Bus, Communication Services (email), Signicat (BankID + signing), SignalR (real-time approval updates) |
| API client | Orval-generated react-query hooks (admin app standard); legacy `useApi` hook being phased out |

## Architecture

Backend solution `Backend/Grantme.sln`:
- `Grantme.API` — 37 admin + 6 client + 5 management controllers; `ClaimsTransformer`, exception middleware
- `Grantme.Common` — entities (~65), services, FluentValidation validators, EF migrations
- `Grantme.Functions` — background jobs
- `Grantme.Tests.Unit` (XUnit + Moq + Shouldly), `Grantme.Tests.Integration` (WebApplicationFactory + AutoRollback)

Frontend apps: `admin` (port 3001), `client`, `management` (3003), `www`. Standalone `e2e/` Playwright suite covering all apps.

## Domain Model (selected)

- **ApplicationPeriod** — the grant round; computed `Status` (Upcoming -> Ongoing -> Completed -> Archived); `PaymentType` Default/Requisition/NoPayment; 10+ template FK columns.
- **Application** — central entity (~60 fields); `Status` Draft -> Submitted -> Preliminary(Approved/Declined) -> Approved/Declined; `Type` Application/Report/Requisition; dynamic form data in `JsonData`.
- **Decision** — formal approve/decline of a set of applications; finalized via `CreateDecision`.
- **Payment / PaymentBatch** — `decimal(18,2)` money; ISO 20022 XML batch export; `TransactionType` Payment/Reversal.
- **Project, Form, Criteria, ApplicationReview, SigningSession, Organisation(User)** — see source for full enum and relationship reference.

Patterns: no repository layer (controllers/services use `DataContext` directly), all entity config in `DataContext.OnModelCreating` (fluent API), `DeleteBehavior.Restrict` on all FKs, soft delete where applicable.

## Engineering Conventions (encoded as always-loaded rules)

These read as a catalog of the team's most common bugs. See [[Claude Code Project Configuration]] for how they are loaded.

- **Multi-tenancy / IDOR**: every query filters by `OrganisationId` from the route; sub-resource endpoints verify the parent exists, belongs to the org, and is not soft-deleted.
- **Backend**: `DateTime.UtcNow` never `.Now`; `CultureInfo.InvariantCulture` on date parsing; always-async EF Core with `CancellationToken`, `AsNoTracking`, `AsSplitQuery`; validate the entity (not the DTO) via `AbstractValidator<TEntity>`; mark required DTO fields `[Required]` so Orval generates them non-optional.
- **Frontend**: React hooks at top level only; no `any` / no double-cast; stable list keys; Mantine v8 DatePicker uses `string | null` not `Date`; `NumberSelect` for enum fields; LiitGrid always sets `startSort`/`startSortOrder` and follows the List + Columns file pattern; files kept under ~300 lines.
- **Dark mode (admin)**: never hardcode colors; use `var(--app-*)` CSS variables and shade-less button colors.
- **i18n**: Swedish default in code via ttag; English in `i18n/en.po`. New admin files need manual `en.po` entries (see [[Claude Code Agent Memory Pattern]]).

## Known Production-Readiness Gaps (from reviewer agent memory)

- SignalR is in-memory only (`AddSignalR()` with no backplane) — horizontal scaling silently breaks real-time updates; the Functions->API bridge globally disables TLS cert validation and the notify endpoint is `[AllowAnonymous]` behind a shared secret.
- Several statistics/dashboard aggregation queries can double-count SBS-imported requisitions when they filter by status/date without `Type == Application`.

## Relationship to This Vault

GrantMe is not a knowledge-management tool; it appears here as the subject of an ingested Claude Code configuration. Its `.claude/` setup is a real-world instance of the layered-context and compounding-memory ideas this vault studies. See [[GrantMe Claude Code Configuration]].
