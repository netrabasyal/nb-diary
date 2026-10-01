// PostgreSQL 17 on the smallest burstable size, inside the private network.
// Password sign-in is off: only Microsoft Entra identities can connect.
param location string
param name string
param subnetId string
param privateDnsZoneId string
param adminIdentityName string
param adminPrincipalId string
param backupRetentionDays int
param tags object

var databaseName = 'nbdiary'

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Standard_B1ms', tier: 'Burstable' }
  properties: {
    version: '17'
    storage: { storageSizeGB: 32, autoGrow: 'Enabled' }
    backup: { backupRetentionDays: backupRetentionDays, geoRedundantBackup: 'Disabled' }
    highAvailability: { mode: 'Disabled' }
    network: {
      delegatedSubnetResourceId: subnetId
      privateDnsZoneArmResourceId: privateDnsZoneId
      publicNetworkAccess: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    }
  }
}

// Until Phase 4 adds a separate migration identity, the API's identity is the database admin.
resource admin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = {
  parent: server
  name: adminPrincipalId
  properties: {
    principalName: adminIdentityName
    principalType: 'ServicePrincipal'
    tenantId: subscription().tenantId
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: server
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
  dependsOn: [admin]
}

output id string = server.id
output name string = server.name
output host string = server.properties.fullyQualifiedDomainName
output databaseName string = databaseName
