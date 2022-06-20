param functionName string = 'GenerateStorageAccount01'
param location string = resourceGroup().location
param versionTag string
param isConsumptionPlan bool = false
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: 'generatestorageaccount'
}

resource serverFarm 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: 'GenerateStorageAccount'
}

resource Insights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'GenerateStorageAccount'
}

resource consumptionPlan 'Microsoft.Web/serverfarms@2020-10-01' = if (isConsumptionPlan) {
  name: 'ConsumptionPlan'
  location: location
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
}

resource GenerateStorageAccount 'Microsoft.Web/sites@2021-03-01' = {
  name: functionName
  tags: {
    'version': versionTag
  }
  kind: 'functionapp,linux'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    serverFarmId: isConsumptionPlan ? consumptionPlan.id : serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('name')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('${Insights.id}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'msi_ID'
          value: uami.properties.clientId
        }
      ]
    }
  }
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: 'GenerateStorageAccount'
  location: location
}

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  // Contributor Role definition ID
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, 'b24988ac-6180-42a0-ab88-20f7382dd24c', uami.id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: uami.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
