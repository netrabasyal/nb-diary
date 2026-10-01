# Deployment

Phase 2 adds the Bicep templates and deploy workflow. Plan:

1. Merge to `main` → build the Flutter web app into the API image → push to Azure Container Registry.
2. Deploy to staging → run the EF migration bundle as a Container Apps Job → smoke test.
3. Promote the same image digest to production with a manual `workflow_dispatch`.

GitHub signs in to Azure with OIDC federated credentials, so no Azure secret is stored in GitHub.

## Container image (available now)

```bash
cd services/api
docker build -t nbdiary-api .
docker run -p 8080:8080 -e ConnectionStrings__Postgres="Host=host.docker.internal;Database=nbdiary;Username=nbdiary;Password=nbdiary_local_only" nbdiary-api
```

The image uses the chiseled ASP.NET runtime: no shell, non-root user.
