// The API's runtime identity in one environment's resource group.
param location string
param environmentName string
param tags object

resource api 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-nbdiary-api-${environmentName}'
  location: location
  tags: tags
}

output apiPrincipalId string = api.properties.principalId
