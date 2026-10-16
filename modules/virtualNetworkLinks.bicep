param privateDnsZoneNames array
param virtualNetworkResourceId string

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [
  for zoneName in privateDnsZoneNames: {
    name: '${zoneName}/${last(split(virtualNetworkResourceId, '/'))}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetworkResourceId
      }
    }
  }
]
