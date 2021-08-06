param storageAccountName string = 'sabicepdemo210806'
param location string = 'westeurope'

param password string = 'supersecret'

@allowed([
  'Hot'
  'Cool'
])
param storageaccessTier string = 'Hot'

var storageSKU = 'Standard_LRS'

resource sa 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageSKU
  }
  properties: {
    accessTier: 'Hot'
  }
}

output sa string = sa.properties.primaryEndpoints.blob


