param prefix string = 'bicepdemo'

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

resource  ag 'Microsoft.DesktopVirtualization/applicationGroups@2021-05-13-preview' = {
  name: '${prefix}-ag'
  location: resourceGroup().location
  properties: {
    friendlyName: 'appgroup for bicep demo'
    applicationGroupType: appGroupType
    hostPoolArmPath: hp.id
  }
}

resource ws 'Microsoft.DesktopVirtualization/workspaces@2021-05-13-preview' = {
  name: '${prefix}-ws'
  location: resourceGroup().location
  properties: {
    friendlyName: 'workspace for bicep demo'
    applicationGroupReferences: [
      ag.id
    ]
  }
}

output hp string = hp.name


