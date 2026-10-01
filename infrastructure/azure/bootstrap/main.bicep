// One-time setup, run by the subscription owner from Azure Cloud Shell (see setup.sh).
// Creates everything GitHub cannot create for itself: resource groups, the shared container
// registry, managed identities, role assignments, budgets and the production delete lock.
// GitHub then deploys main.bicep into the staging and production resource groups only.
targetScope = 'subscription'

@description('Azure region for all resources.')
param location string = 'australiaeast'

@description('GitHub repository allowed to deploy, as owner/name.')
param githubRepository string = 'netrabasyal/nb-diary'

@description('Email address that receives budget alerts.')
param alertEmail string

@description('Monthly budget for production, in the billing currency.')
param prodBudget int = 70

@description('Monthly budget for staging and the shared registry, in the billing currency.')
param nonProdBudget int = 25

@description('First day of the month the budgets start from (yyyy-MM-01).')
param budgetStartDate string = utcNow('yyyy-MM-01')

var tags = {
  app: 'nbdiary'
  owner: 'netrabasyal'
  module: 'platform'
}

var environments = [
  { name: 'staging', short: 'stg' }
  { name: 'prod', short: 'prd' }
]

resource sharedRg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'rg-nbdiary-shared'
  location: location
  tags: union(tags, { env: 'shared' })
}

resource envRgs 'Microsoft.Resources/resourceGroups@2024-11-01' = [for env in environments: {
  name: 'rg-nbdiary-${env.name}'
  location: location
  tags: union(tags, { env: env.name })
}]

// Runtime identity of the API in each environment. Created here so its registry access exists
// before the first deployment pulls the image.
module envIdentities 'environment.bicep' = [for (env, i) in environments: {
  name: 'nbdiary-bootstrap-${env.name}-identity'
  scope: envRgs[i]
  params: {
    location: location
    environmentName: env.name
    tags: union(tags, { env: env.name })
  }
}]

module shared 'shared.bicep' = {
  name: 'nbdiary-bootstrap-shared'
  scope: sharedRg
  params: {
    location: location
    githubRepository: githubRepository
    tags: union(tags, { env: 'shared' })
    runtimePrincipalIds: [for i in range(0, length(environments)): envIdentities[i].outputs.apiPrincipalId]
  }
}

// GitHub's deploy identities get rights on their own environment's resource group and nothing else.
module stagingAccess 'deploy-access.bicep' = {
  name: 'nbdiary-bootstrap-staging-access'
  scope: envRgs[0]
  params: {
    deployPrincipalId: shared.outputs.deployStagingPrincipalId
  }
}

module prodAccess 'deploy-access.bicep' = {
  name: 'nbdiary-bootstrap-prod-access'
  scope: envRgs[1]
  params: {
    deployPrincipalId: shared.outputs.deployProdPrincipalId
    deleteLock: true
  }
}

// Budgets cover each environment's resource group plus the ME_ group Container Apps creates for
// its own networking, so alerts include everything NB Diary costs and nothing else in the subscription.
resource prodBudgetAlert 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-nbdiary-prod'
  properties: {
    category: 'Cost'
    amount: prodBudget
    timeGrain: 'Monthly'
    timePeriod: { startDate: budgetStartDate }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: ['rg-nbdiary-prod', 'ME_cae-nbdiary-prod_rg-nbdiary-prod_${location}']
      }
    }
    notifications: budgetNotifications
  }
}

resource nonProdBudgetAlert 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-nbdiary-nonprod'
  properties: {
    category: 'Cost'
    amount: nonProdBudget
    timeGrain: 'Monthly'
    timePeriod: { startDate: budgetStartDate }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: ['rg-nbdiary-staging', 'ME_cae-nbdiary-staging_rg-nbdiary-staging_${location}', 'rg-nbdiary-shared']
      }
    }
    notifications: budgetNotifications
  }
}

var budgetNotifications = {
  actual50: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 50, thresholdType: 'Actual', contactEmails: [alertEmail] }
  actual80: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 80, thresholdType: 'Actual', contactEmails: [alertEmail] }
  actual100: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 100, thresholdType: 'Actual', contactEmails: [alertEmail] }
  forecast100: { enabled: true, operator: 'GreaterThanOrEqualTo', threshold: 100, thresholdType: 'Forecasted', contactEmails: [alertEmail] }
}

output acrName string = shared.outputs.acrName
output acrLoginServer string = shared.outputs.acrLoginServer
output deployStagingClientId string = shared.outputs.deployStagingClientId
output deployProdClientId string = shared.outputs.deployProdClientId
