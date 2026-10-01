// Key Vault for the few secrets the API will need (sign-in client secret from Phase 3).
// Access is by Azure RBAC only; the API's identity can read secrets, nothing more.
param location string
param name string
param purgeProtection bool
param readerPrincipalId string
param tags object

var keyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'

resource vault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // Purge protection can never be turned off again, so it is production only.
    enablePurgeProtection: purgeProtection ? true : null
    publicNetworkAccess: 'Enabled'
  }
}

resource apiReadsSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, readerPrincipalId, keyVaultSecretsUser)
  scope: vault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output name string = vault.name
output uri string = vault.properties.vaultUri
