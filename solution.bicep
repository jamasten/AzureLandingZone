targetScope = 'subscription'

@description('The location for the resources in the deployment.')
param location string = deployment().location

@description('The local administrator password for deploying virtual machines.')
@secure()
param vmPassword string

@description('The local administrator username for deploying virtual machines.')
param vmUsername string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'landing-zone'
  location: location
  properties: {}
}

module network './modules/network.bicep' = {
  name: 'NetworkingTemplate'
  scope: resourceGroup
  params: {
    location: location
  }
}

module sharedServices './modules/sharedServices.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    subnetResourceId: network.outputs.subnetResourceId
    vmPassword: vmPassword
    vmUsername: vmUsername
  }
}
