# Azure Virtual Datacenter

_Enabling developer agility and operational consistency without compromising security and governance._

[![Build Status](https://travis-ci.org/Azure/vdc.svg?branch=master)](https://travis-ci.org/Azure/vdc)

Microsoft Azure Virtual Datacenter (VDC) is an approach for designing a foundational cloud architecture for enterprises. It provides a vision for enterprise IT in the cloud and a strategy for implementing it. For more information about the approach, visit [Azure Virtual Datacenter](https://aka.ms/vdc).

The VDC approach is composed of three main components:
- A set of reference architectures
- An engagement model that guides customers on choosing the right reference architectures
- An automation toolkit that follows the engagement model to provide a DevOps approach on deploying different reference architectures

## Automation Toolkit

This repository contains the _Azure Virtual Datacenter Automation Toolkit_. The toolkit is set of deployment artifacts, Azure Resource Manager templates and scripts, and an orchestration engine. It allows you to deploy an example shared services infrastructure environment and example workload environments capable of hosting different applications. It also allows you to deploy a simulated on-premises environment, hosted in Azure, for testing purposes.

## Documentation

- [Understanding the concepts](docs/understand/readme.md)
  - [Prerequisite Azure knowledge](docs/understand/azure.md) - Resources for understanding the Azure services that the toolkit utilizes.
  - [Understanding the Automation Toolkit](docs/understand/toolkit.md) - Explains the important concepts in the toolkit.
  - [Understanding environment types](docs/understand/environment-types.md) - Describes the built-in environment types that the toolkit can deploy.
  - [Common workflow](docs/understand/workflow.md) - Covers the typical usage pattern for the tools in the toolkit.
  - [Roles and permissions](docs/understand/roles.md) - Lists the custom roles that are provided by default in the toolkit.
  - [Modules](docs/understand/modules.adoc) - Explains the modules included in the toolkit.

- [Setting up the toolkit](docs/setup/readme.md)
  - [Run the Docker image](docs/setup/setup-docker.md) (Recommended) - How to setup the toolkit using Docker.
  - [Run on your local machine](docs/setup/setup-local.md) - How to setup the toolkit natively.

- [Usage patterns for the toolkit](docs/use/readme.md)
  - [Your first deployment](docs/use/your-first-deployment.md) - Quick start tutorial for deploying the _simulated on-premises archetype_.
  - [General considerations](docs/use/general-considerations.md) - Items to evaluate before deploying any archetype.
  - [Creating archetype configuration files](docs/use/configuration-files.adoc) - How to prepare an `archetype.json` file.
    - [Common parameters](docs/use/common-parameters.adoc) - Parameters used in all archetype configuration files.
    - [Common workload parameters](docs/use/common-workload-config.adoc) - Parameters used by workload archetype configuration files.
  - [Archetype deployment considerations](docs/use/archetype-deployment-considerations.md) - Items to evaluate that are specific to _shared-services_ and _workload_ environments.
  - [Validating deployments](docs/use/deployment-validation.adoc) - How to validate an archetype configuration.

- [Extending the toolkit](docs/extend/readme.md)
  - [Creating new modules](docs/extend/creating-new-modules.adoc) - How to create a new module.
  - [Creating new archetypes](docs/extend/creating-new-archetypes.adoc) - How to create a new archetype.
  - [Using the integration tests](docs/extend/integration-testing.adoc) - How to run and add new integration tests.

- [Script Reference](docs/reference/readme.md)
  - [policy-assignment.py](docs/reference/script-policy-assignment.adoc) Update subscription policy post-deployment
  - [role-creation.py](docs/reference/script-role-creation.adoc) Create subscription roles
  - [subscription.py](docs/reference/script-subscription.adoc) Create management groups and subscriptions
  - [vdc.py](docs/reference/script-vdc.adoc) Deploy archetypes and modules

- [Archetypes](docs/archetypes/readme.md)
  - [Simulated on-premises environment](docs/archetypes/on-premises/overview.adoc)
  - [Shared services](docs/archetypes/shared-services/overview.adoc)
  - [IaaS N-tier architecture](docs/archetypes/ntier-iaas/overview.adoc)
  - [Azure Kubernetes Service (AKS)](docs/archetypes/aks/overview.adoc)
  - [App Service Environment + SQL Database](docs/archetypes/paas/overview.adoc)
  - [SAP HANA](docs/archetypes/sap-hana/overview.adoc)
  - [Cloudbreak](docs/archetypes/cloudbreak/overview.adoc)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit [https://cla.microsoft.com](https://cla.microsoft.com).

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
