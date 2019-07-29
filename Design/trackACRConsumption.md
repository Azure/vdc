# Track Azure Revenue Consumption (ACR) via Azure Resource Manager deployments
* Owner: Jorge Cotillo (jcotillo@microsoft.com)
* Reviewers: Virtual Datacenter (VDC) Team
* Status: Draft, revision 1.0

## Abstract
From Microsoft Azure Website:

_As a software partner for Azure, your solutions require Azure components or they need to be deployed directly on the Azure infrastructure. Customers who deploy a partner solution and provision their own Azure resources can find it difficult to gain visibility into the status of the deployment, and get optics into the impact on Azure growth. When you add a higher level of visibility, you align with the Microsoft sales teams and gain credit for Microsoft partner programs._

_Microsoft now offers a method to help partners better track Azure usage of customer deployments of their software on Azure. The new method uses Azure Resource Manager to orchestrate the deployment of Azure services._

Virtual Datacenter toolkit aims to help partners consuming the different engineering assets to track ACR without enforcing it to the broader community.

### Goals
- Track ACR via Resource Manager templates

### Non-goals
This effort does not include
- Azure Resource Manager APIs: Partners calling Resource Manager APIs directly to deploy a Resource Manager template or to generate the API calls to directly provision Azure services.
- Terraform: Partners using a cloud orchestrator such as Terraform to deploy a Resource Manager template or directly to deploy Azure services.

## Proposal
To help partners consuming VDC engineering assets track ACR, the proposal is to use a combination of a default parameter, updates to the existing modules (Resource Manager templates), and finally VDC toolkit engine code changes.

### Default ACR parameter
This parameter will exist in two locations:

- Archetype parameters
- Resource Manager template

The default name will be: __usageAttributionId__

Here's an example on how the parameter will look in an Archetype parameters:

```json
"ArchetypeParameters" : {
    "UsageAttributionId" "00000000-0000-0000-0000-000000000000"
}
```

Here's an example on how the parameter will look in a Resource Manager template:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "usageAttributionId": {
            "type": "string",
            "defaultValue": "",
            "metadata": {
                "description": "Azure partner customer usage attribution Identifier. The GUID must be previously registered."
            }
        }
    }
}
```

__NOTE:__ The Archetype parameters and Resource Manager template will have more content, for simplicity sake, these examples only show part of the JSON content.

### Updates to existing modules
When creating a new module (Resource Manager template), the requirement will be to add the following nested deployment resource.

```json
{
    "apiVersion": "2018-02-01",
    "name": "[concat('pid-', parameters('usageAttributionId'))]",
    "condition": "[not(empty(parameters('usageAttributionId')))]",
    "type": "Microsoft.Resources/deployments",
    "properties": {
        "mode": "Incremental",
        "template": {
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "resources": []
        }
    }
}
```

__NOTE:__ Notice the _condition_ introduced in the Resource Manager template, this condition allows the resource to be deployed _only_ when it contains a value, otherwise skips this deployment. This way, consumers of the VDC toolkit assets that do not require to keep track of ARC, can leave this parameter empty.

### VDC toolkit engine changes
The proposed change impacts the following Powershell module: _ModuleConfigurationDeployment.ps1_ and the function: _Merge-Parameters_.

Merge-Parameters function will analyze the Archetype parameters and will look for the parameter called: _usageAttributionId_.

- If the parameter does not exist, do not pass _usageAttributionId_ to the Azure Resource Manager deployment
- If the parameters exists, pass _usageAttributionId_ to the Azure Resource Manager deployment by injecting this parameter to the parameter hashtable already generated

## References:
- https://docs.microsoft.com/en-us/azure/marketplace/azure-partner-customer-usage-attribution

[^1]: https://docs.microsoft.com/en-us/azure/marketplace/azure-partner-customer-usage-attribution

