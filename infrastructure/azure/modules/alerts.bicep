// Production alerts by email: server errors from the API and the database running short of room.
param name string
param alertEmail string
param containerAppId string
param postgresServerId string
param tags object

resource actionGroup 'Microsoft.Insights/actionGroups@2024-10-01-preview' = {
  name: 'ag-${name}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'nbdiary'
    enabled: true
    emailReceivers: [
      { name: 'owner', emailAddress: alertEmail, useCommonAlertSchema: true }
    ]
  }
}

resource serverErrors 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${name}-5xx'
  location: 'global'
  tags: tags
  properties: {
    description: 'The API returned server errors.'
    severity: 2
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'requests5xx'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.App/containerApps'
          dimensions: [
            { name: 'statusCodeCategory', operator: 'Include', values: ['5xx'] }
          ]
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroup.id }]
  }
}

resource databaseStorage 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${name}-db-storage'
  location: 'global'
  tags: tags
  properties: {
    description: 'PostgreSQL storage is over 80% full.'
    severity: 2
    enabled: true
    scopes: [postgresServerId]
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'storagePercent'
          metricName: 'storage_percent'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroup.id }]
  }
}
