using 'main.bicep'

param environmentName = 'staging'
param vnetAddressPrefix = '10.40.0.0/16'
param postgresBackupRetentionDays = 7
param image = readEnvironmentVariable('NBDIARY_IMAGE')
param registryServer = readEnvironmentVariable('NBDIARY_REGISTRY')
