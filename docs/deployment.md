# Deployment

Azure setup, access and the one-time Cloud Shell steps: [infrastructure/azure/README.md](../infrastructure/azure/README.md).

## Pipeline

1. **deploy** (every merge to `main` that touches the app, API or infrastructure):
   build the Flutter web app → copy it into `services/api/web-dist` → build the API image →
   push to the shared registry → start staging PostgreSQL if it is stopped →
   deploy `main.bicep` to `rg-nbdiary-staging` → smoke test `/health/ready` and `/` →
   tag the digest `staging`.
2. **promote** (manual): deploy the digest tagged `staging` to `rg-nbdiary-prod` → smoke test.
3. **staging-db-stop** (nightly, 23:00 Sydney standard time): stop staging PostgreSQL.

Workflows are skipped until `setup.sh` has saved the Azure connection details as repository
variables (`AZURE_SUBSCRIPTION_ID` and others). Database migrations join the pipeline in Phase 4.

## Container image

```bash
cd services/api
docker build -t nbdiary-api .
docker run -p 8080:8080 -e ConnectionStrings__Postgres="Host=host.docker.internal;Database=nbdiary;Username=nbdiary;Password=nbdiary_local_only" nbdiary-api
```

The image uses the chiseled ASP.NET runtime: no shell, non-root user. To include the web app, run
`flutter build web --release --no-web-resources-cdn` in `apps/mobile` and copy `build/web/.` into
`services/api/web-dist/` before building.

## In Azure

The API reads these settings (set by `modules/containerapp.bicep`):

| Setting | Value |
| --- | --- |
| `ConnectionStrings__Postgres` | Host, database and identity name; no password; `SSL Mode=VerifyFull` |
| `Postgres__ManagedIdentityClientId` | Client ID of the API's managed identity (Entra token sign-in) |
| `ASPNETCORE_ENVIRONMENT` | `Staging` or `Production` |
