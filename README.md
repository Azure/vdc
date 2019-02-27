Azure Virtual Datacenter Automation Toolkit Deployment Guide
============

[![Build Status](https://travis-ci.org/Azure/vdc.svg?branch=master)](https://travis-ci.org/Azure/vdc)

This guide walks you through the deployment of a Microsoft Azure Virtual
Datacenter (VDC) using a set of templates and scripts collectively referred to
as the Azure Virtual Datacenter Automation Toolkit. You can use the Azure VDC
Automation Toolkit to create a fully functional, trusted network extension for
on-premises IT infrastructure.

The toolkit allows you to deploy an example VDC central IT shared services infrastructure and several workload environments capable of hosting different applications. It also allows you to deploy a simulated Azure hosted on-premises
environment for testing purposes.

We'll discuss how VDC automation works and explain how to extend these sample 
assets to deploy a working VDC customized for your organization. For a broader
introduction to the Azure Virtual Datacenter concept and details on the
architecture this toolkit implements, see the [Azure Virtual Datacenter
conceptual
overview](https://azure.microsoft.com/resources/azure-virtual-datacenter/).


## Contents
*   [Prerequisites](documentation/01-prerequisites.md)
*   [How VDC automation works](documentation/02-how-vdc-automation-works.md)
*   [Parameters files](documentation/03-parameters-files.md)
*   [Creating subscription roles](documentation/04-creating-subscription-roles.md)
*   [Launching the main automation script](documentation/05-launching-the-main-automation-script.md)
*   [Deploying the simulated on-premises environment](documentation/06-deploying-the-simulated-on-premises-environment.md)
*   [Deploying the sample VDC shared services and central IT infrastructure](documentation/07-deploying-the-sample-vdc-shared-service.md)
*   [Deploying workloads](documentation/08-deploying-spokes.md)
    *   [Workload example 1: PaaS N-tier architecture](documentation/08-deploying-workloads-example1-paas-n-tier-architecture.md)
    *   [Workload example 2: IaaS N-tier architecture](documentation/08-deploying-workloads-example2-iaas-n-tier-architecture.md)
    *   [Workload example 3: Hadoop deployment](documentation/08-deploying-workloads-example3-hadoop-deployment.md)
    *   [Workload example 4: SAP HANA deployment](documentation/08-deploying-workloads-example4-sap-hana-deployment.md)
*   [Post-deployment subscription policy updates](documentation/09-post-deployment-subscription-policy-updates.md)
*   [Extending the Azure VDC Automation Toolkit](documentation/10-extending-the-azure-vdc-automation-toolkit.md)
*   [Deployment validation](documentation/11-deployment-validation.md)
*   [Integration testing](documentation/12-integration-testing.md)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
