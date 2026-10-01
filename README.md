# NB Diary

A modular personal productivity platform. The first module is **NB Diary Gym**, a workout tracker
that works offline. V1 runs as a web app you install to your iPhone home screen.

## Repository

```text
apps/mobile/          Flutter app (web first; iOS and Android later)
services/api/         ASP.NET Core (.NET 10) modular monolith
packages/contracts/   API contracts and shared test vectors (from Phase 4)
infrastructure/azure/ Bicep templates (from Phase 2)
database/             Seed data and admin scripts (from Phase 6)
tests/e2e/            Browser tests (Playwright)
docs/                 Architecture, decisions, runbooks
.github/workflows/    api-ci, app-ci, security
```

## Getting started

See [docs/local-development.md](docs/local-development.md). In short:

```bash
docker compose up -d postgres
cd services/api && dotnet run --project src/NbDiary.Api --urls http://localhost:5137
cd apps/mobile && flutter run -d chrome
```

## Docs

[Architecture](docs/architecture.md) · [Decisions](docs/decisions.md) · [Roadmap](docs/roadmap.md) ·
[Security](docs/security.md) · [Testing](docs/testing.md) · [Cost](docs/cost-management.md)
