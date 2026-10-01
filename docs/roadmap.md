# Roadmap

Each phase ends with working, tested software and updated docs.

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Discovery and architecture | Done (2026-10-01) |
| 1 | Repository and development environment | Done (2026-10-01) |
| 2 | Azure infrastructure (Bicep, staging and production) | In progress |
| 3 | Authentication (Entra External ID, session cookies) | Not started |
| 4 | Database and API foundation, sync skeleton, isolation tests | Not started |
| 5 | Flutter design system | Not started |
| 6 | Exercise library and ingestion | Not started |
| 7 | Workout builder | Not started |
| 8 | Live workout tracking | Not started |
| 9 | Offline synchronisation | Not started |
| 10 | History and personal records | Not started |
| 11 | Analytics | Not started |
| 12 | Security hardening | Not started |
| 13 | Production web release | Not started |
| 14 | Privacy and release documentation | Not started |
| Later | App Store (optional) | Deferred |

## Phase 1 acceptance criteria

- [x] API runs locally against Docker PostgreSQL; `/health/live` and `/health/ready` respond.
- [x] Web app runs locally; data written to Drift survives closing and reopening.
- [x] The production web build opens with no connection after the first visit (browser test).
- [x] `api-ci`, `app-ci` and `security` workflows pass on the pull request.
- [ ] Opened from the iPhone home screen with no connection (manual check, after Phase 2 deploys it).

## Phase 2 acceptance criteria

- [x] Bicep templates for both environments build with no linter warnings (`infra-ci`).
- [x] The API image includes the web app and serves it with security headers.
- [ ] One-time setup (`infrastructure/azure/bootstrap/setup.sh`) run in the `nb-lab-1` subscription.
- [ ] A merge to `main` deploys to staging and passes the smoke test.
- [ ] `promote` deploys the same image to production.
- [ ] Staging opens on an iPhone, installs to the home screen and starts with no connection.
