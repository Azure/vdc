Deploying workloads
===================================

Before deploying workload workspaces, make sure you have properly configured the top-level workload parameters file. You need to correctly specify the information about your shared services network and NVA, and make sure the workload name and IP configuration do not interfere with any other workloads previously deployed.

To deploy multiple workloads, you can modify the sample workload parameters file setting unique values for the *deployment-name*, *vnet-address-prefix*, and *default-subnet-address-prefix* parameters, then redeploy using steps listed in the example workload deployment instructions listed below.

The workload deployments need to reference shared services deployment output files, so make sure the "vdc-storage" parameter in the top-level workload parameters file is the same as the one you used when deploying the shared services resources.

**Note:** Spokes created using the current version of the VDC Automation Toolkit can only communicate with resources within the workload and those hosted in the on-premises environment. As a result, Internet access to and from the workloads needs to be managed through the on-premises network. Future versions of the toolkit will allow workload Internet access managed through the Hub network.

Example Spokes
--------------
The VDC Automation Toolkits provides several sample workload deployments as examples of integrating workload deployments with VDC automation.

*   [Spoke example 1: PaaS N-tier architecture](08-deploying-workloads-example1-paas-n-tier-architecture.md)
*   [Spoke example 2: IaaS N-tier architecture](08-deploying-workloads-example2-iaas-n-tier-architecture.md)
*   [Spoke example 3: Hadoop Cloudbreak deployment](08-deploying-workloads-example3-hadoop-deployment.md)
*   [Spoke example 4: SAP HANA deployment](08-deploying-workloads-example4-sap-hana-deployment.md)