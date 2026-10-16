# Azure Landing Zone

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureLandingZones%2Fmain%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzureLandingZones%2Fmain%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/AzureLandingZones/main/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/AzureLandingZones/main/solution.json'
````

## Description

A landing zone is the core infrastructure needed to support a workload in Azure.  Typically this involves your networking and identity. This solution assumes your identities are cloud identities managed by Entra ID and is meant to be a simple, flat network architecture with some core services.

The solution will also deploy the following Azure resources:

+ Virtual Network with Subnets
+ Route Table with Route
+ Private DNS Zones
+ Azure Firewall with Public IP Address & Policy
+ Network Watcher
+ Bastion with Public IP Address
+ Key Vault with Secrets
+ Log Analytics Workspace
+ Azure Blobs with Container
