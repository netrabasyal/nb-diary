using 'main.bicep'

param environmentName = 'prod'
param vnetAddressPrefix = '10.41.0.0/16'
param postgresBackupRetentionDays = 14
param image = readEnvironmentVariable('NBDIARY_IMAGE')
param registryServer = readEnvironmentVariable('NBDIARY_REGISTRY')
param alertEmail = readEnvironmentVariable('NBDIARY_ALERT_EMAIL', '')
