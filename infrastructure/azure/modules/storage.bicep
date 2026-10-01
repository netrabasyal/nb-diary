// Blob storage for exercise media, user data exports and database dumps.
// No anonymous access and no account keys: only Entra identities with a data role can read.
param location string
param name string
param contributorPrincipalId string
param tags object

var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource account 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: account
  name: 'default'
  properties: {
    deleteRetentionPolicy: { enabled: true, days: 7 }
    containerDeleteRetentionPolicy: { enabled: true, days: 7 }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = [for container in ['exercise-media', 'exports', 'db-dumps']: {
  parent: blobService
  name: container
  properties: { publicAccess: 'None' }
}]

// Exports are temporary download files; database dumps are kept for a month.
resource lifecycle 'Microsoft.Storage/storageAccounts/managementPolicies@2025-01-01' = {
  parent: account
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'expire-exports'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: { blobTypes: ['blockBlob'], prefixMatch: ['exports/'] }
            actions: { baseBlob: { delete: { daysAfterModificationGreaterThan: 7 } } }
          }
        }
        {
          name: 'expire-db-dumps'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: { blobTypes: ['blockBlob'], prefixMatch: ['db-dumps/'] }
            actions: { baseBlob: { delete: { daysAfterModificationGreaterThan: 30 } } }
          }
        }
      ]
    }
  }
}

resource apiWritesBlobs 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, contributorPrincipalId, storageBlobDataContributor)
  scope: account
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor)
    principalId: contributorPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output name string = account.name
output blobEndpoint string = account.properties.primaryEndpoints.blob
