# Local development (Windows)

Everything in V1 runs on Windows. No Mac is needed.

## Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Git | any recent | |
| Docker Desktop | any recent | Runs PostgreSQL and Azurite |
| .NET SDK | 10.0 | `services/api/global.json` pins the feature band |
| Flutter | 3.47.5 stable | Includes Dart 3.13 |
| Node.js | 22 | Only for the browser tests in `tests/e2e` |
| Chrome or Edge | any recent | For running the web app |

## First run

```powershell
git clone https://github.com/netrabasyal/nb-diary.git
cd nb-diary
docker compose up -d postgres
```

### API

```powershell
cd services/api
dotnet run --project src/NbDiary.Api --urls http://localhost:5137
```

Expected: `http://localhost:5137/health/live` returns `Healthy`, and `/health/ready` returns
`Healthy` while the Docker PostgreSQL is running (`Unhealthy` with status 503 if it isn't).
The OpenAPI document is at `/openapi/v1.json` in Development.

### Web app

```powershell
cd apps/mobile
flutter pub get
flutter run -d chrome
```

The app opens on the Gym tab. Settings shows how many times it has opened on this device and which
browser storage Drift chose. `flutter run` doesn't send the cross-origin isolation headers, so Drift
uses IndexedDB there; production uses the faster origin private file system.

To try the production build with the real headers and offline support:

```powershell
cd apps/mobile
flutter build web --release --no-web-resources-cdn
cd ../../tests/e2e
npm ci
npm run serve   # http://localhost:8085
```

## Tests

```powershell
# API: unit, architecture and PostgreSQL integration tests (needs Docker running)
cd services/api; dotnet test

# App: unit, widget and database tests
cd apps/mobile; flutter analyze; flutter test

# Browser: offline start and data persistence (needs the web build above)
cd tests/e2e; npx playwright install chromium; npx playwright test
```

## Changing the database schema (app)

1. Edit the tables in `apps/mobile/lib/platform/database/app_database.dart` and bump `schemaVersion`.
2. Run `dart run build_runner build --delete-conflicting-outputs`.
3. Run `dart run drift_dev make-migrations` to snapshot the schema and generate migration tests.
4. Commit the generated files; CI fails if they are out of date.
