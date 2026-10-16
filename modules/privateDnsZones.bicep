param virtualNetworkResourceId string

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var privateDnsZoneNames = [
  'privatelink.${(privateDnsZoneSuffixes_AzureWebSites[environment().name]??'appservice.${cloudSuffix}')}'
  'privatelink.wvd.${(privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name]??cloudSuffix)}'
  'privatelink-global.wvd.${(privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name]??cloudSuffix)}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink${replace(environment().suffixes.keyvaultDns,'vault','vaultcore')}'
]
var privateDnsZoneSuffixes_AzureVirtualDesktop = {
  AzureCloud: 'microsoft.com'
  AzureUSGovernment: 'azure.us'
  USNat: null
  USSec: null
}
var privateDnsZoneSuffixes_AzureWebSites = {
  AzureCloud: 'azurewebsites.net'
  AzureUSGovernment: 'azurewebsites.us'
  USNat: null
  USSec: null
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = [
  for item in privateDnsZoneNames: {
    name: item
    location: 'global'
  }
]

module virtualNetworkLinks 'virtualNetworkLinks.bicep' = {
    params: {
      privateDnsZoneNames: privateDnsZoneNames
      virtualNetworkResourceId: virtualNetworkResourceId
    }
    dependsOn: [
      privateDnsZones
    ]
}
