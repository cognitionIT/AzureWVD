param prefix string = 'bicepdemo'

@secure()
param password string = 'supersecret'

@allowed([
  'Pooled'
  'Personal'
])
param hostpoolType string = 'Pooled'

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadbalancerType string = 'BreadthFirst'

var appGroupType = 'Desktop'

resource hp 'Microsoft.DesktopVirtualization/hostPools@2021-05-13-preview' = {
  name: '${prefix}-hp'
  location: resourceGroup().location
  properties: {
    friendlyName: 'hostpool for the bicep demo'
    hostPoolType: hostpoolType
    loadBalancerType: loadbalancerType
    preferredAppGroupType: appGroupType
  }
}

resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: 'name'
  location: resourceGroup().location
  properties: {
    friendlyName: 'friendlyName'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hp.id
  }
}

output hp string = hp.name
