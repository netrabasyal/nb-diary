# Azure infrastructure

Everything runs in the existing **nb-lab-001** subscription, Australia East, in three resource groups:

| Resource group | Contents |
| --- | --- |
| `rg-nbdiary-shared` | Container registry (Basic), GitHub's two deploy identities |
| `rg-nbdiary-staging` | Staging: network, PostgreSQL, Container App, Key Vault, storage, logs |
| `rg-nbdiary-prod` | Production: the same, plus email alerts and a delete lock |

Container Apps also creates an `ME_cae-nbdiary-<env>_...` group for its own networking. Nothing
else in nb-lab-001 is touched.

## Files

| File | Purpose |
| --- | --- |
| `bootstrap/main.bicep` | One-time, subscription level: resource groups, registry, identities, access, budgets, lock |
| `bootstrap/setup.sh` | Runs the bootstrap from Azure Cloud Shell and saves the connection details in GitHub |
| `main.bicep` | One environment; deployed by GitHub Actions on every release |
| `modules/*.bicep` | Monitoring, network, Key Vault, storage, PostgreSQL, Container App, alerts |
| `staging.bicepparam`, `prod.bicepparam` | Per-environment settings |

## One-time setup

You need to be **Owner** of nb-lab-001 (it creates role assignments). In the Azure portal, open
**Cloud Shell** (the `>_` icon at the top), choose **Bash**, then run:

```bash
gh auth login            # GitHub.com > HTTPS > Login with a web browser; enter the code shown
gh repo clone netrabasyal/nb-diary && cd nb-diary
./infrastructure/azure/bootstrap/setup.sh
```

It takes a few minutes and ends with "Done". Then in GitHub open **Actions > deploy > Run workflow**
on `main` to create staging. After that, every merge to `main` deploys staging automatically.

To send budget emails somewhere other than your Azure sign-in address, add `--email you@example.com`.

## Releasing to production

Check staging, then run **Actions > promote > Run workflow** on `main`. It deploys the exact image
staging is running (same digest).

## Access model

- GitHub signs in with OIDC from the `main` branch only. No Azure password or key is stored in GitHub.
- Staging's deploy identity can change `rg-nbdiary-staging` and push images. Production's can change
  `rg-nbdiary-prod` and read images. Neither can grant itself more: the role-assignment right is
  limited to *Key Vault Secrets User* and *Storage Blob Data Contributor*.
- The API runs as a user-assigned managed identity per environment. It pulls images, signs in to
  PostgreSQL with an Entra token, reads Key Vault secrets and reads and writes blobs.
- PostgreSQL has no public endpoint and no passwords. Key Vault and storage accept Entra sign-in only.

## Validate locally

```bash
az bicep build --file infrastructure/azure/main.bicep
az bicep lint --file infrastructure/azure/main.bicep
```

## Removing an environment

Production has a `CanNotDelete` lock. To remove staging: `az group delete -n rg-nbdiary-staging`.
