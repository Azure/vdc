# Understanding environment types

There are two special _archetypes_ defined in the Azure Virtual Datacenter Automation Toolkit.
These are:

- simulated on-premises environment
- shared services environment

The toolkit performs special actions for these archetypes and you will need to identify them when using the toolkit. All other deployment types are identified as `workload`.

This identifier is used when invoking the [`vdc.py` script](../reference/script-vdc.md).

## Simulated on-premises environment

Identifier: `on-premises`

This archetype defines a _simulated_ on-premises environment that is hosted in Azure. It is intended for testing VDC automation without needing to connect to your actual on-premise resources.

## Shared services environment

Identifier: `shared-services`

This archetype provisions a set of services that are expected to be shared by multiple workloads. These include Active Directory Domain Services (AD DS), Azure Key Vault, Log Analytics, and a connection to the on-premises network.

See [Extend Active Directory Domain Services (AD DS) to Azure](https://docs.microsoft.com/azure/architecture/reference-architectures/identity/adds-extend-domain) for proven practices.

## Other environment types

Identifier: `workload`

Deploys a workload virtual network where resources are deployed and securely connects this network to shared services network.

NOTE: The current version of the toolkit assumes that workloads are connected to a shared services environment and that network traffic is routed through the shared services' VNet. In future versions of the toolkit, workloads will not necessarily adhere to this pattern.

## Next steps

Learn about the [default roles](roles.md) provided by in the toolkit.