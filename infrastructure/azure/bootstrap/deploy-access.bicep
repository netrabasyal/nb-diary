// What GitHub's deploy identity may do in one environment's resource group.
param deployPrincipalId string

@description('Stop anything in this resource group being deleted (production).')
param deleteLock bool = false

var roles = {
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  rbacAdmin: 'f58310d9-a9f6-439a-9e8d-f62e7b41a168'
  keyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  storageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// The only roles main.bicep hands out (to the API's runtime identity).
var assignableRoles = '${roles.keyVaultSecretsUser}, ${roles.storageBlobDataContributor}'

resource contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployPrincipalId, roles.contributor)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.contributor)
    principalId: deployPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignments are limited by condition to the two data roles above, so the deploy identity
// cannot grant itself or anyone else Owner or Contributor.
resource rbacAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployPrincipalId, roles.rbacAdmin)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roles.rbacAdmin)
    principalId: deployPrincipalId
    principalType: 'ServicePrincipal'
    conditionVersion: '2.0'
    condition: '((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/write\'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${assignableRoles}})) AND ((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/delete\'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${assignableRoles}}))'
  }
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (deleteLock) {
  name: 'nbdiary-no-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Production data. Remove this lock deliberately before deleting anything here.'
  }
}
