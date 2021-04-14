param location string = 'eastus'
param workspaceName string = 'ws-wvd-bicep'
param hostpoolName string = 'hp-wvd-bicep'
param appgroupName string = 'ag-wvd-bicep'
param preferredAppGroupType string = 'Desktop'
param hostPoolType string = 'pooled'
param loadbalancertype string = 'BreadthFirst'
param appgroupType string = 'Desktop'

resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
    name: hostpoolName
    location: location
    properties: {
      friendlyName: 'Bicep generated Host pool'
      hostPoolType : hostPoolType
      loadBalancerType : loadbalancertype
      preferredAppGroupType: preferredAppGroupType
    }
  }

resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
name: appgroupName
location: location
properties: {
    friendlyName: 'Bicep generated application Group'
    applicationGroupType: appgroupType
    hostPoolArmPath: hp.id
  }
}

resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
    name: workspaceName
    location: location
    properties: {
        friendlyName: 'Bicep generated Workspace'
      applicationGroupReferences: [
        ag.id
      ]
    }
  }
output workspaceid string = ws.id
