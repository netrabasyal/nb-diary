// Private network: one subnet for Container Apps, one delegated to PostgreSQL. The database has no
// public endpoint and is reachable only from inside this network.
param location string
param name string
param addressPrefix string
param tags object

// Split the /16 into a /23 for Container Apps and a /27 for PostgreSQL.
var appsPrefix = cidrSubnet(addressPrefix, 23, 0)
var postgresPrefix = cidrSubnet(addressPrefix, 27, 16)

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [addressPrefix] }
    subnets: [
      {
        name: 'snet-apps'
        properties: {
          addressPrefix: appsPrefix
          delegations: [
            { name: 'apps', properties: { serviceName: 'Microsoft.App/environments' } }
          ]
        }
      }
      {
        name: 'snet-postgres'
        properties: {
          addressPrefix: postgresPrefix
          delegations: [
            { name: 'postgres', properties: { serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers' } }
          ]
        }
      }
    ]
  }
}

resource postgresDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: '${name}.private.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

resource postgresDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: postgresDns
  name: name
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

output appsSubnetId string = vnet.properties.subnets[0].id
output postgresSubnetId string = vnet.properties.subnets[1].id
output postgresDnsZoneId string = postgresDns.id
