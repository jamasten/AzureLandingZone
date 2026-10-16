param location string

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' = {
  name: 'network-watcher'
  location: location
  properties: {}
}

resource routeTable 'Microsoft.Network/routeTables@2025-09-01' = {
  name: 'route-table'
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource route 'Microsoft.Network/routeTables/routes@2025-09-01' = {
  parent: routeTable
  name: 'firewall'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.0.0.4'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'virtual-network'
  location: location
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/26'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.0.64/26'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureFuctionSubnet'
        properties: {
          addressPrefix: '10.0.1.128/26'
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureNetAppFiles'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.Netapp.Volumes'
              properties: {
                serviceName: 'Microsoft.Netapp/volumes'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'Workload'
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                '*'
              ]
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn: [
    networkWatcher
  ]
}

resource firewallPIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'firewall-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2025-09-01' = {
  name: 'firewall-policy'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-09-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AnyAny'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'Default'
        priority: 100
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2025-09-01' = {
  name: 'firewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {}
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          publicIPAddress: {
            id: firewallPIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'AzureFirewallSubnet')
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}


resource bastionPIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: 'bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          publicIPAddress: {
            id: bastionPIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'AzureBastionSubnet')
          }
        }
      }
    ]
  }
}

output subnetResourceId string = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'Workload')
