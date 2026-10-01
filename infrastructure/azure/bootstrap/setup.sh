#!/usr/bin/env bash
# One-time Azure setup for NB Diary. Run it in Azure Cloud Shell (Bash) as the owner of the
# subscription:
#
#   gh auth login
#   gh repo clone netrabasyal/nb-diary && cd nb-diary
#   ./infrastructure/azure/bootstrap/setup.sh
#
# Options: --subscription NAME (default nb-lab-1), --email ADDRESS (budget and alert emails,
# default: the signed-in Azure account), --location REGION (default australiaeast).
# Safe to run again: everything it creates is updated in place.
set -euo pipefail

subscription="nb-lab-1"
location="australiaeast"
email=""
repo="netrabasyal/nb-diary"

while [ $# -gt 0 ]; do
  case "$1" in
    --subscription) subscription="$2"; shift 2 ;;
    --email) email="$2"; shift 2 ;;
    --location) location="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Using subscription '$subscription'"
az account set --subscription "$subscription"
subscription_id="$(az account show --query id -o tsv)"
tenant_id="$(az account show --query tenantId -o tsv)"

if [ -z "$email" ]; then
  email="$(az account show --query user.name -o tsv)"
  # Personal Microsoft accounts can show as live.com#name@example.com.
  email="${email##*#}"
fi
echo "    Budget and alert emails go to: $email"

echo "==> Registering the Azure services NB Diary uses (once per subscription)"
for namespace in Microsoft.App Microsoft.ContainerRegistry Microsoft.DBforPostgreSQL \
  Microsoft.KeyVault Microsoft.ManagedIdentity Microsoft.Network Microsoft.OperationalInsights \
  Microsoft.Insights Microsoft.Storage Microsoft.Consumption; do
  az provider register --namespace "$namespace" --wait --output none
done

echo "==> Creating resource groups, registry, identities, access and budgets"
outputs="$(az deployment sub create \
  --name nbdiary-bootstrap \
  --location "$location" \
  --template-file "$here/main.bicep" \
  --parameters location="$location" githubRepository="$repo" alertEmail="$email" \
  --query properties.outputs -o json)"

value() { echo "$outputs" | jq -r ".$1.value"; }
acr_name="$(value acrName)"
acr_login_server="$(value acrLoginServer)"
staging_client_id="$(value deployStagingClientId)"
prod_client_id="$(value deployProdClientId)"

# These are identifiers, not secrets: GitHub signs in with OIDC, so no password is stored.
declare -A variables=(
  [AZURE_TENANT_ID]="$tenant_id"
  [AZURE_SUBSCRIPTION_ID]="$subscription_id"
  [AZURE_CLIENT_ID_STAGING]="$staging_client_id"
  [AZURE_CLIENT_ID_PROD]="$prod_client_id"
  [ACR_NAME]="$acr_name"
  [ACR_LOGIN_SERVER]="$acr_login_server"
  [ALERT_EMAIL]="$email"
)

if command -v gh > /dev/null && gh auth status > /dev/null 2>&1; then
  echo "==> Saving the connection details as GitHub repository variables"
  for name in "${!variables[@]}"; do
    gh variable set "$name" --repo "$repo" --body "${variables[$name]}"
  done
  echo
  echo "Done. Next: in GitHub, open Actions > deploy > Run workflow (branch main)."
else
  echo
  echo "Done. GitHub CLI is not signed in, so add these under GitHub > Settings >"
  echo "Secrets and variables > Actions > Variables:"
  for name in "${!variables[@]}"; do
    echo "  $name = ${variables[$name]}"
  done
fi
