# Preparing to deploy with the toolkit

Before starting a deployment with the toolkit, you must validate your Azure environment configuration and ensure it meets the following prerequisites.

## Rights to subscription

You will need [Contributor](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor) to the targeted subscriptions.

## Ensure subscription quotas are sufficient

Deployments to Azure can fail if any of the [subscription limits or quotas](https://docs.microsoft.com/azure/azure-subscription-service-limits) are exceeded. Make sure the planned resources will not exceed these quotas or limits for the targeted subscriptions.

You can use empty subscriptions during testing and development to minimize the chance of exceeded a limit.

## Confirm IP ranges do not conflict

To interact with your on-premises network, your central IT shared services and workload networks need to have a compatible IP address configuration. IP ranges for the shared services and workloads should not conflict with each other or any on-premises datacenters the VDC connects with. Integrate the networks in your VDC with your existing on-premises IP Address Management (IPAM) scheme before choosing the IP ranges for the main central IT shared services and any planned workload networks you plan to deploy.

## Next steps

After reviewing these general considerations, read about additional [considerations for archetype deployments](archetype-deployment-considerations.md).