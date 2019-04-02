# Deploying archetypes

After deploying a Simulated on-premises environment, make sure to deploy a `Shared services` archetype. 

When deploying an `archetype`, make sure you have properly configured the archetype configuration file (`archetype.json`). 

In `workload` deployments, make sure to specify the information about your shared services environment, add the workload deployment name and that the IP configuration do not interfere with shared services network or any other workloads previously deployed.

When deploying multiple workloads, you should modify the sample archetype configuration files and set unique values for the `deployment-name`, `vnet-address-prefix`, and `default-subnet-address-prefix` parameters, then redeploy using steps listed in the example workload deployment instructions listed below.

The workload deployments need to reference shared services deployment output files, so make sure the `vdc-storage` parameter in the archetype configuration file is the same as the one you used when deploying the shared services resources.

**NOTE** 
> Workloads deployed using the current version of the toolkit can only communicate with resources within the workload and those hosted in the on-premises environment (East - West connectivity). Workload to Workload connectivity is not enabled, Internet access from shared services and the different workloads (Internet egress) is managed through a Network Virtual Appliance, similarly, Internet access to the workloads (Internet ingress) is managed through a Network Virtual Appliance deployed in shared services network (North - South connectivity).

## Example archetypes

The toolkit provides several sample workload archetypes:

- [Shared services deployment](../archetypes/shared-services/overview.adoc)
- [ASE + SQL Database deployment](../archetypes/ntier-iaas/overview.adoc)
- [IaaS N-tier deployment](../archetypes/paas/overview.adoc)
- [Hadoop Cloudbreak deployment](../archetypes/cloudbreak/overview.adoc)
- [SAP HANA deployment](../archetypes/sap-hana/overview.adoc)

## Next steps

Learn about [creating an archetype configuration file](configuration-files.adoc) to make a deployment.
