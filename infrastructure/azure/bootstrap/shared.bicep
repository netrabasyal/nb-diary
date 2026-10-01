// Shared resources: the container registry and GitHub's deploy identities.
param location string
param githubRepository string
param tags object

@description('Principal IDs of the API runtime identities that pull images.')
param runtimePrincipalIds array

var roles = {
  acrPull: '7f951dce-4ed6-4b33-b3a4-f2d1a7e7c3fb'
  acrPush: '8311e382-0749-4cb8-b61a-304f252e45ec'
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: 'crnbdiary${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

// GitHub signs in with OIDC: a token for a workflow running on the main branch of this repository
// is exchanged for an Azure token. No secret is stored in GitHub. Pull request runs get nothing.
resource deployStaging 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-nbdiary-deploy-staging'
  location: location
  tags: tags
}

resource deployStagingGithub 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  parent: deployStaging
  name: 'github-main'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubRepository}:ref:refs/heads/main'
    audiences: ['api://AzureADTokenExchange']
  }
}

resource deployProd 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-nbdiary-deploy-prod'
  location: location
  tags: tags
}

resource deployProdGithub 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  parent: deployProd
  name: 'github-main'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubRepository}:ref:refs/heads/main'
    audiences: ['api://AzureADTokenExchange']
  }
}

// Staging builds and pushes images. Production only reads them, to promote the tested digest.
resource stagingPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, deployStaging.id, roles.acrPush)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.acrPush)
    principalId: deployStaging.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource prodPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, deployProd.id, roles.acrPull)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.acrPull)
    principalId: deployProd.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource runtimePull 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in runtimePrincipalIds: {
  name: guid(acr.id, principalId, roles.acrPull)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.acrPull)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output deployStagingPrincipalId string = deployStaging.properties.principalId
output deployStagingClientId string = deployStaging.properties.clientId
output deployProdPrincipalId string = deployProd.properties.principalId
output deployProdClientId string = deployProd.properties.clientId
