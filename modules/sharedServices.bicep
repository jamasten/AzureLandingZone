param location string
param subnetResourceId string
@secure()
param vmPassword string
param vmUsername string

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: 'key-vault-${uniqueString(subscription().id)}'
  location: location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: [
        {
          id: subnetResourceId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId

  }
  dependsOn: []
}

resource secret1 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  parent: keyVault
  name: 'LocalAdminPassword'
  properties: {
    value: vmPassword
  }
}

resource secret2 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  parent: keyVault
  name: 'LocalAdminUsername'
  properties: {
    value: vmUsername
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: 'log-analytics-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-06-01' = {
  name: 'storage${uniqueString(subscription().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowCrossTenantDelegationSas: false
    dualStackEndpointPreference: {
      publishIpv6Endpoint: false
    }
    allowedCopyScope: 'PrivateLink'
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      ipv6Rules: []
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetResourceId
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: true
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        table: {
          keyType: 'Account'
          enabled: true
        }
        queue: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2026-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    staticWebsite: {
      enabled: false
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2026-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: false
      days: 0
    }
  }
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2026-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2026-06-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource artifactsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-06-01' = {
  parent: blobServices
  name: 'artifacts'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Container'
  }
}
