# Roles and permissions

The Azure Virtual Datacenter Automation Toolkit encourages the use of separation of responsibilities using [role-based access control (RBAC)](https://docs.microsoft.com/azure/active-directory/role-based-access-control-configure) to determine which users and teams can create and manage specific resources.

Before deploying, you need to create the appropriate roles in your Azure AD tenant and assign the appropriate users to these roles. See the [reference documentation for `role-creation.py`](../reference/script-role-creation.adoc) for instructions on using the provided scripts to deploy roles for your subscription.

The toolkit provides 4 custom roles that act as a baseline recommendation:

- SecOps
- NetOps
- SysOps
- DevOps

These custom roles are defined in [`aad.roles.json`](../../roles/aad.roles.json).

## SecOps

The SecOps role is responsible for security within the central IT infrastructure and shared services virtual network. This includes managing security devices, keys, and secrets, along with controlling user access to the environment. SecOps is responsible for monitoring traffic coming from outside the VDC environment and between the workspaces and the central IT infrastructure for potential attacks or vulnerabilities, as well as controlling what external internet locations are accessible from inside the VDC. Security policies and access rules at the resource group and individual resources level are managed by SecOps, and any workload requests for exceptions or modifications of these policies and rules is handled by SecOps. SecOps is responsible for administrating the central IT Key Vault. SecOps can create, modify, and read secrets and cryptographic keys in the vault, while other roles can only use items in the vault to encrypt/decrypt data in the virtual datacenter. Because all traffic going into and out of a VDC must pass through the central firewall, the central IT SecOps role is responsible for managing requests from workload teams to modify central firewall settings.

- `Microsoft.Insights/diagnosticsettings/write`
- `Microsoft.KeyVault/hsmPools/read`
- `Microsoft.KeyVault/hsmPools/write`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.KeyVault/vaults/secrets/read`
- `Microsoft.KeyVault/vaults/secrets/write`
- `Microsoft.KeyVault/vaults/accessPolicies/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/locations/operations/read`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.Network/loadBalancers/write`
- `Microsoft.Network/locations/operations/read`
- `Microsoft.Network/networkInterfaces/write`
- `Microsoft.Network/publicIPAddresses/write`
- `Microsoft.Network/routeTables/read`
- `Microsoft.Network/routeTables/write`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.Resources/deployments/read`
- `Microsoft.Resources/deployments/write`
- `Microsoft.Authorization/policyAssignments/write`
- `Microsoft.Authorization/policyDefinitions/write`
- `Microsoft.Authorization/roleDefinitions/read`
- `Microsoft.Authorization/roleDefinitions/write`

## NetOps

The NetOps role controls the network infrastructure and traffic routing for the central IT shared services virtual network. NetOps is responsible for maintaining any virtual networking devices, network configurations, and traffic management rules that apply to the shared services network. NetOps is responsible for configuring and maintaining the VNet peering connecting the workload and services network.

- `Microsoft.Network/applicationSecurityGroups/write`
- `Microsoft.Network/networkSecurityGroups/write`
- `Microsoft.Network/ddosProtectionPlans/write`
- `Microsoft.Network/locations/operations/read`
- `Microsoft.Network/publicIPAddresses/write`
- `Microsoft.Network/routeTables/read`
- `Microsoft.Network/routeTables/write`
- `Microsoft.Network/virtualNetworks/read`
- `Microsoft.Network/virtualNetworks/write`
- `Microsoft.Network/azureFirewalls/read`
- `Microsoft.Network/azureFirewalls/write`
- `Microsoft.Network/applicationGateways/read`
- `Microsoft.Network/applicationGateways/write`
- `Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.Network/networkInterfaces/read`
- `Microsoft.Network/networkInterfaces/write`
- `Microsoft.Storage/operations/read`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.Resources/deployments/read`
- `Microsoft.Resources/deployments/write`
- `Microsoft.Authorization/policyAssignments/write`
- `Microsoft.Authorization/policyDefinitions/write`
- `Microsoft.Authorization/roleDefinitions/read`
- `Microsoft.Authorization/roleDefinitions/write`

## SysOps

SysOps is responsible for monitoring, configuring diagnostics, and setting up alerts and notifications for resources hosted in the central IT infrastructure. On detecting an issue, the SysOps team investigates and escalates to the appropriate team responsible for resolving the issue.

- `Microsoft.OperationalInsights/workspaces/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/locations/operations/read`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.Network/networkInterfaces/write`
- `Microsoft.Storage/operations/read`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.Resources/deployments/read`
- `Microsoft.Resources/deployments/write`
- `Microsoft.Resources/subscriptions/resourceGroups/read`
- `Microsoft.Resources/subscriptions/resourceGroups/write`
- `Microsoft.Authorization/policyAssignments/write`
- `Microsoft.Authorization/policyDefinitions/write`
- `Microsoft.Authorization/roleDefinitions/read`
- `Microsoft.Authorization/roleDefinitions/write`

## DevOps

DevOps is responsible for building and deploying workload applications and services hosted in the workload environments.

- `Microsoft.Network/virtualNetworks/read`
- `Microsoft.Network/virtualNetworks/write`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.Network/networkInterfaces/read`
- `Microsoft.Network/networkInterfaces/write`
- `Microsoft.Storage/operations/read`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.Resources/deployments/read`
- `Microsoft.Resources/deployments/write`
- `Microsoft.Authorization/policyAssignments/write`
- `Microsoft.Authorization/policyDefinitions/write`
- `Microsoft.Authorization/roleDefinitions/read`
- `Microsoft.Authorization/roleDefinitions/write`

Each of the deployment steps described later in this guide are designed to be performed by one of these roles. Organizations can vary widely on how their internal IT teams are structured, but before executing a deployment step you need to make sure the executing user has the required subscription permissions to deploy the resources during that step.

## Next steps

Learn about the [modules](modules.adoc) that come with the toolkit.