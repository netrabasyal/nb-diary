# Testing

| Layer | Tool | Where | Runs in |
| --- | --- | --- | --- |
| API unit and HTTP tests | xUnit, `WebApplicationFactory` | `services/api/tests/NbDiary.Api.Tests` | `api-ci` |
| API database integration | Testcontainers (PostgreSQL 17) | same project, `Category=Integration` | `api-ci` (needs Docker) |
| Module boundaries | NetArchTest | `services/api/tests/NbDiary.ArchitectureTests` | `api-ci` |
| App unit, widget, database | `flutter_test`, Drift in-memory and file databases | `apps/mobile/test` | `app-ci` |
| Drift migrations | `drift_dev make-migrations` generated tests | `apps/mobile/test/drift` | `app-ci` (from schema v2) |
| Browser end-to-end | Playwright, Chromium and WebKit | `tests/e2e/specs` | `app-ci` |

## Current browser tests

- The app opens offline after the first visit, and the launch count stored in Drift goes 1 → 2 → 3
  across two reloads, the last one offline.
- The server sends the cross-origin isolation headers Drift needs.

Flutter draws to a canvas, so browser tests turn on Flutter's accessibility tree and find
elements by their accessible names, the same way VoiceOver does.

## Planned

Security isolation suite (User A vs User B) and authorisation matrix in Phase 4; sync fault-injection
tests in Phase 9; the full critical journey (sign in → offline workout → sync → no duplicates →
records and analytics) in Phase 13.
