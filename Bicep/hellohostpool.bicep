param prefix string = 'bicepdemo'

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

resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: '${prefix}-hp'
  location: resourceGroup().location
  properties: {
    friendlyName: 'hostpool for the bicep demo'
    hostPoolType: hostpoolType
    loadBalancerType: loadbalancerType
    preferredAppGroupType: appGroupType
  }
}

resource  ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: '${prefix}-ag'
  location: resourceGroup().location
  properties: {
    friendlyName: 'appgroup for bicep demo'
    applicationGroupType: appGroupType
    hostPoolArmPath: resourceId('Microsoft.DesktopVirtualization/hostpools', 'REQUIRED')
  }
}

resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: '${prefix}-ws'
  location: resourceGroup().location
  properties: {
    friendlyName: 'workspace for bicep demo'
  }
}

output hp string = hp.id


