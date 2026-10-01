# Decision log

Each entry records what was decided, why, and when. Newest last. Change a decision by adding a
new entry that supersedes the old one; don't edit history.

## ADR-001: Keep the proposed stack
- **Date:** 2026-10-01 · **Status:** Accepted
- Flutter, ASP.NET Core modular monolith on Azure Container Apps, PostgreSQL Flexible Server,
  Entra External ID, Bicep, GitHub Actions. No serious technical problem was found that forces a change.

## ADR-002: Web app first; App Store deferred
- **Date:** 2026-10-01 · **Status:** Accepted (owner decision)
- **Why:** avoid the Apple Developer Program fee and the need for a Mac while the app is for personal use.
- **Consequences:** Flutter web, installed to the iPhone home screen. Codemagic, TestFlight and
  App Store work move to a later optional phase. Rest timer alerts can't fire while the phone is locked.

## ADR-003: Serve the web app from the API container
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** one deployment, no extra hosting cost, and one origin for the app and API, which keeps
  cookie sign-in simple and lets us set the security headers Drift and the CSP need.

## ADR-004: Server-side sign-in with a session cookie (backend for frontend)
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** no tokens in the browser, and Microsoft limits browser-only (SPA) refresh tokens to 24 hours.
- **Consequences:** the API is a confidential client with a certificate in Key Vault; CSRF protection
  via SameSite=Strict plus a required custom header.

## ADR-005: Drift for on-device storage
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** typed queries, reactive streams, transactions and tested migrations; runs in the browser
  through WebAssembly and natively on phones with the same code. Alternatives: sqflite (no web,
  untyped), PowerSync (replaces our sync engine, adds a vendor), Isar and ObjectBox (not SQLite).
- **Notes:** `web/sqlite3.wasm` and `web/drift_worker.js` must match `pubspec.lock`;
  run `apps/mobile/tool/update_web_database_assets.sh` after upgrading.

## ADR-006: Own service worker instead of Flutter's
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** Flutter no longer generates a service worker by default. `web/flutter_bootstrap.js`
  loads the app without one, and `web/nb_service_worker.js` caches the app's files for offline use.
  API, sign-in and health routes are never cached.

## ADR-007: Regroup API modules into bounded contexts
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** sets can't be validated without their session, so Sessions, Sets and Templates form one
  Training module. See [architecture.md](architecture.md).

## ADR-008: Local development environment; Azure hosts staging and production only
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** saves roughly AUD 30–40 a month with no loss of separation. Local credentials in
  `docker-compose.yml` are for your machine only.

## ADR-009: PostgreSQL on a private network with managed-identity authentication
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** the "allow Azure services" firewall rule admits any Azure customer's resources, and
  VNet integration costs almost nothing. The networking mode can't be changed after creation.

## ADR-010: Client-generated UUIDv7 IDs, transactional outbox and idempotent sync
- **Date:** 2026-10-01 · **Status:** Accepted
- **Why:** a set's ID is created once on the device, so retries can never create a second copy.

## ADR-011: Phase 0 open decisions settled with the recommended defaults
- **Date:** 2026-10-01 · **Status:** Accepted (owner said "yes start")
- Region Australia East; free Azure web address for now; keep the screen on during workouts for the
  rest timer; API scales to zero; text-only exercise library in V1.

## ADR-012: Placeholder application identifier
- **Date:** 2026-10-01 · **Status:** Accepted
- The Flutter project uses `com.nbdiary` as its organisation identifier. It only matters for a
  future App Store build and must be confirmed before any store release.
