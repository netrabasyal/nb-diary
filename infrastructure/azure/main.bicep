// One NB Diary environment (staging or prod), deployed by GitHub Actions into its own resource
// group in the nb-lab-1 subscription. The resource group, the API's identity and the shared
// container registry come from bootstrap/main.bicep.
targetScope = 'resourceGroup'

@allowed(['staging', 'prod'])
param environmentName string

param location string = resourceGroup().location

@description('Container image to run, by digest, for example crnbdiaryxyz.azurecr.io/nbdiary-api@sha256:...')
param image string

@description('Login server of the shared container registry.')
param registryServer string

@description('Address space for this environment\'s virtual network.')
param vnetAddressPrefix string

@description('Days of PostgreSQL point-in-time backups.')
param postgresBackupRetentionDays int = 7

@description('Email address for production alerts. Leave empty to skip alerts.')
param alertEmail string = ''

var isProd = environmentName == 'prod'
var suffix = take(uniqueString(resourceGroup().id), 8)
var tags = {
  app: 'nbdiary'
  env: environmentName
  owner: 'netrabasyal'
  module: 'platform'
}

resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: 'id-nbdiary-api-${environmentName}'
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    name: 'nbdiary-${environmentName}'
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    name: 'vnet-nbdiary-${environmentName}'
    addressPrefix: vnetAddressPrefix
    tags: tags
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    name: 'kv-nbd-${environmentName}-${take(suffix, 6)}'
    purgeProtection: isProd
    readerPrincipalId: apiIdentity.properties.principalId
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    name: 'stnbd${environmentName}${suffix}'
    contributorPrincipalId: apiIdentity.properties.principalId
    tags: tags
  }
}

module postgres 'modules/postgres.bicep' = {
  name: 'postgres'
  params: {
    location: location
    name: 'psql-nbdiary-${environmentName}-${suffix}'
    subnetId: network.outputs.postgresSubnetId
    privateDnsZoneId: network.outputs.postgresDnsZoneId
    adminIdentityName: apiIdentity.name
    adminPrincipalId: apiIdentity.properties.principalId
    backupRetentionDays: postgresBackupRetentionDays
    tags: tags
  }
}

module app 'modules/containerapp.bicep' = {
  name: 'containerapp'
  params: {
    location: location
    environmentName: environmentName
    image: image
    registryServer: registryServer
    identityId: apiIdentity.id
    identityClientId: apiIdentity.properties.clientId
    identityName: apiIdentity.name
    subnetId: network.outputs.appsSubnetId
    logAnalyticsCustomerId: monitoring.outputs.workspaceCustomerId
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    postgresHost: postgres.outputs.host
    postgresDatabase: postgres.outputs.databaseName
    tags: tags
  }
}

module alerts 'modules/alerts.bicep' = if (isProd && !empty(alertEmail)) {
  name: 'alerts'
  params: {
    name: 'nbdiary-${environmentName}'
    alertEmail: alertEmail
    containerAppId: app.outputs.id
    postgresServerId: postgres.outputs.id
    tags: tags
  }
}

output appUrl string = 'https://${app.outputs.fqdn}'
output postgresServerName string = postgres.outputs.name
