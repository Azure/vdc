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

- `Microsoft.Resources/deployments/*`
- `Microsoft.Authorization/policyDefinitions/*`
- `Microsoft.Authorization/policyAssignments/*`
- `Microsoft.OperationalInsights/workspaces/*`
- `Microsoft.OperationsManagement/*`
- `Microsoft.Security/*`
- `Microsoft.ADHybridHealthService/addsservices/read`
- `Microsoft.ADHybridHealthService/configuration/read`
- `Microsoft.ADHybridHealthService/services/read`
- `Microsoft.Advisor/configurations/read`
- `Microsoft.Advisor/suppressions/read`
- `Microsoft.AlertsManagement/actionRules/read`
- `Microsoft.AlertsManagement/smartDetectorAlertRules/read`
- `Microsoft.Authorization/classicAdministrators/read`
- `Microsoft.Authorization/locks/read`
- `Microsoft.Authorization/locks/write`
- `microsoft.authorization/permissions/read`
- `Microsoft.Authorization/policyAssignments/read`
- `Microsoft.Authorization/policyAssignments/write`
- `Microsoft.Authorization/policyDefinitions/read`
- `Microsoft.Authorization/policySetDefinitions/read`
- `Microsoft.Authorization/roleAssignments/read`
- `Microsoft.Authorization/roleDefinitions/read`
- `Microsoft.Automation/automationAccounts/read`
- `Microsoft.Compute/availabilitySets/read`
- `Microsoft.Compute/disks/read`
- `Microsoft.Compute/galleries/read`
- `Microsoft.Compute/images/read`
- `Microsoft.Compute/proximityPlacementGroups/read`
- `Microsoft.Compute/restorePointCollections/read`
- `Microsoft.Compute/sharedVMImages/read`
- `Microsoft.Compute/snapshots/read`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachineScaleSets/read`
- `Microsoft.Consumption/Budgets/read`
- `Microsoft.ContainerInstance/containerGroups/read`
- `Microsoft.CostManagement/CloudConnectors/read`
- `Microsoft.CostManagement/Exports/read`
- `Microsoft.CostManagement/ExternalSubscriptions/read`
- `Microsoft.DBforMySQL/servers/read`
- `Microsoft.DBforPostgreSQL/servers/read`
- `Microsoft.DBforPostgreSQL/serversv2/read`
- `Microsoft.EventHub/namespaces/AuthorizationRules/read`
- `Microsoft.EventHub/namespaces/AuthorizationRules/write`
- `Microsoft.EventHub/namespaces/disasterrecoveryconfigs/read`
- `Microsoft.EventHub/namespaces/eventhubs/authorizationrules/read`
- `Microsoft.EventHub/namespaces/eventhubs/consumergroups/read`
- `Microsoft.EventHub/namespaces/eventhubs/consumergroups/write`
- `Microsoft.EventHub/namespaces/eventhubs/read`
- `Microsoft.EventHub/namespaces/eventhubs/write`
- `Microsoft.EventHub/namespaces/read`
- `Microsoft.EventHub/namespaces/write`
- `Microsoft.GuestConfiguration/guestConfigurationAssignments/read`
- `Microsoft.Insights/actiongroups/read`
- `Microsoft.Insights/activityLogAlerts/read`
- `Microsoft.Insights/alertrules/read`
- `Microsoft.Insights/autoscalesettings/read`
- `Microsoft.Insights/components/read`
- `Microsoft.Insights/diagnosticSettings/read`
- `Microsoft.Insights/diagnosticSettings/write`
- `Microsoft.Insights/eventtypes/values/read`
- `Microsoft.Insights/extendedDiagnosticSettings/read`
- `Microsoft.Insights/logprofiles/read`
- `Microsoft.Insights/metricalerts/read`
- `Microsoft.Insights/metrics/read`
- `Microsoft.Insights/scheduledqueryrules/read`
- `Microsoft.Insights/webtests/read`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.Network/applicationGateways/read`
- `Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/read`
- `Microsoft.Network/applicationSecurityGroups/read`
- `Microsoft.Network/azureFirewalls/read`
- `Microsoft.Network/connections/read`
- `Microsoft.Network/ddosCustomPolicies/read`
- `Microsoft.Network/ddosProtectionPlans/read`
- `Microsoft.Network/dnszones/read`
- `Microsoft.Network/expressRouteCircuits/read`
- `Microsoft.Network/frontdoors/read`
- `Microsoft.Network/frontdoorWebApplicationFirewallPolicies/read`
- `Microsoft.Network/loadBalancers/read`
- `Microsoft.Network/localNetworkGateways/read`
- `Microsoft.Network/natGateways/read`
- `Microsoft.Network/networkIntentPolicies/read`
- `Microsoft.Network/networkInterfaces/read`
- `Microsoft.Network/networkProfiles/read`
- `Microsoft.Network/networkSecurityGroups/read`
- `Microsoft.Network/networkWatchers/read`
- `Microsoft.Network/privateEndpoints/read`
- `Microsoft.Network/privateLinkServices/read`
- `Microsoft.Network/publicIPAddresses/read`
- `Microsoft.Network/publicIPPrefixes/read`
- `Microsoft.Network/routeFilters/read`
- `Microsoft.Network/routeTables/read`
- `Microsoft.Network/secureGateways/read`
- `Microsoft.Network/serviceEndpointPolicies/read`
- `Microsoft.Network/trafficmanagerprofiles/read`
- `Microsoft.Network/trafficManagerUserMetricsKeys/read`
- `Microsoft.Network/virtualHubs/read`
- `Microsoft.Network/virtualNetworkGateways/read`
- `Microsoft.Network/virtualNetworks/read`
- `Microsoft.Network/virtualNetworkTaps/read`
- `Microsoft.Network/virtualWans/read`
- `Microsoft.Network/vpnGateways/read`
- `Microsoft.Network/vpnSites/read`
- `Microsoft.PolicyInsights/remediations/read`
- `Microsoft.Portal/consoles/read`
- `Microsoft.Portal/dashboards/read`
- `Microsoft.Portal/userSettings/read`
- `Microsoft.RecoveryServices/vaults/read`
- `Microsoft.Resources/links/read`
- `Microsoft.Resources/subscriptions/resourceGroups/read`
- `Microsoft.Resources/subscriptions/resourcegroups/write`
- `Microsoft.Sql/instancePools/read`
- `Microsoft.Sql/managedInstances/read`
- `Microsoft.Sql/servers/read`
- `Microsoft.Sql/virtualClusters/read`
- `Microsoft.Storage/storageAccounts/ListAccountSas/action`
- `Microsoft.Storage/storageAccounts/listKeys/action`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.Web/certificates/read`
- `Microsoft.Web/connectionGateways/read`
- `Microsoft.Web/connections/read`
- `Microsoft.Web/customApis/read`
- `Microsoft.Web/hostingEnvironments/read`
- `Microsoft.Web/publishingUsers/read`
- `Microsoft.Web/serverFarms/read`
- `Microsoft.Web/sites/read`
- `Microsoft.Web/sourceControls/read`
- `Microsoft.WorkloadMonitor/monitors/read`
- `Microsoft.WorkloadMonitor/notificationSettings/read`

## NetOps

The NetOps role controls the network infrastructure and traffic routing for the central IT shared services virtual network. NetOps is responsible for maintaining any virtual networking devices, network configurations, and traffic management rules that apply to the shared services network. NetOps is responsible for configuring and maintaining the VNet peering connecting the workload and services network.

- `Microsoft.Resources/deployments/*`
- `Microsoft.Resources/subscriptions/resourceGroups/read`
- `Microsoft.Resources/subscriptions/resourcegroups/write`
- `Microsoft.Network/applicationSecurityGroups/write`
- `Microsoft.Authorization/locks/write`
- `Microsoft.Network/networkSecurityGroups/read`
- `Microsoft.Network/networkSecurityGroups/write`
- `Microsoft.Network/networkSecurityGroups/join/action`
- `Microsoft.Network/ddosProtectionPlans/write`
- `Microsoft.Network/locations/operations/read`
- `Microsoft.Network/publicIPAddresses/write`
- `Microsoft.Network/routeTables/read`
- `Microsoft.Network/routeTables/write`
- `Microsoft.Network/routeTables/join/action`
- `Microsoft.Network/virtualNetworks/read`
- `Microsoft.Network/virtualNetworks/write`
- `Microsoft.Network/virtualNetworks/peer/action`
- `Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action`
- `Microsoft.Network/azureFirewalls/read`
- `Microsoft.Network/azureFirewalls/write`
- `Microsoft.Network/applicationGateways/read`
- `Microsoft.Network/applicationGateways/write`
- `Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.Insights/diagnosticSettings/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.Network/networkInterfaces/read`
- `Microsoft.Network/networkInterfaces/write`
- `Microsoft.Storage/operations/read`
- `Microsoft.Storage/storageAccounts/listKeys/action`
- `Microsoft.Storage/storageAccounts/listAccountSas/action`
- `Microsoft.Storage/storageAccounts/read`
- `Microsoft.Storage/storageAccounts/write`
- `Microsoft.OperationalInsights/workspaces/sharedKeys/action`
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

- `Microsoft.Resources/deployments/*`
- `Microsoft.Resources/subscriptions/resourceGroups/read`
- `Microsoft.Resources/subscriptions/resourcegroups/write`
- `Microsoft.Network/virtualNetworks/read`
- `Microsoft.Network/virtualNetworks/write`
- `Microsoft.KeyVault/vaults/read`
- `Microsoft.KeyVault/vaults/write`
- `Microsoft.Compute/availabilitySets/write`
- `Microsoft.Compute/virtualMachines/extensions/read`
- `Microsoft.Compute/virtualMachines/extensions/write`
- `Microsoft.Compute/virtualMachines/read`
- `Microsoft.Compute/virtualMachines/write`
- `Microsoft.ContainerRegistry/registries/write`
- `Microsoft.ContainerRegistry/registries/read`
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