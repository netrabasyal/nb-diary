# Architecture

NB Diary is a modular personal productivity platform. The first module is **Gym**.
This document is the short, living version of the Phase 0 architecture package
(version 2, web first). Decisions and their reasons are logged in [decisions.md](decisions.md).

## Shape of the system

```text
Browser (Flutter web app, installed to the iPhone home screen)
  UI (Riverpod) → repositories → Drift SQLite (WebAssembly) → outbox → sync engine
        │
        │ HTTPS, same address, session cookie
        ▼
NB Diary API (.NET 10 modular monolith, Azure Container Apps)
  also serves the web app's files
        │ Entra auth through managed identity, private network
        ▼
PostgreSQL Flexible Server (Burstable B1ms)

Supporting: Entra External ID (sign-in), Key Vault, Blob Storage,
Application Insights, Container Registry. Infrastructure in Bicep,
delivered by GitHub Actions.
```

## Principles

- **Offline first.** The on-device database is what the UI reads. The network is only for sync.
- **One codebase.** Flutter for the web now; the same code can build iOS and Android later.
- **Modular monolith.** One API process; each module owns its schema and code, and talks to
  others only through public contracts. Architecture tests enforce this.
- **Modules plug into a shell.** The app shell owns sign-in, navigation, settings, the design
  system, the database connection and sync. A module implements `NbModule`
  (`apps/mobile/lib/platform/module/nb_module.dart`) and is listed in `registeredModules`.
- **No secrets on the client.** The browser holds only an HttpOnly session cookie.
- **Billing stays out of the training domain.** Only an `IEntitlementService` interface exists in V1.

## API modules (bounded contexts)

| Module | Owns |
| --- | --- |
| Identity | Token validation, mapping external identities to internal users |
| Users | Profile, preferences, devices, data export, account deletion |
| Exercises | System library, custom exercises, favourites, ingestion |
| Training | Templates, planned workouts, sessions, session exercises, sets |
| Records | Personal records, derived from sets |
| Progress | Body measurements; analytics endpoints later |
| Sync | Push/pull protocol, idempotency records, change cursor |
| Billing | Interface only in V1 |

Modules are added as projects under `services/api/src/Modules/` in Phase 4.

## Environments

| Environment | Where | Purpose |
| --- | --- | --- |
| Development | Your PC: Docker PostgreSQL and Azurite, API and app run locally | Daily work |
| Staging | Azure subscription `nbdiary-nonprod` | Every merge to `main` deploys here |
| Production | Azure subscription `nbdiary-prod` | Manual promotion of the tested image |

## Current status

Phase 1 (repository and development environment) is in progress. See [roadmap.md](roadmap.md).
