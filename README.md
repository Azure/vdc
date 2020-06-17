# Azure Virtual Datacenter

[![Build Status](https://travis-ci.org/Azure/vdc.svg?branch=master)](https://travis-ci.org/Azure/vdc)

This toolkit assists in the composition of _reference architectures_ for Microsoft Azure.
It is intended for _enterprise_ customers with strict security and compliance requirements.
The toolkit for designing and standardizing centrally-managed infastructure as well as application-specific infrastructure.
It encourages the use of [modern devops principles](Docs/design-principles.md).

## Documentation
- The easiest way to get started with the toolkit is to follow our [quickstart guide](Docs/quickstart.md).
- Checkout the [latest release notes](Docs/Release/2019-09.md).
- If you want to utilize the master orchestration script please refer to the following [documentation](Docs/masterOrchestration)

## Repo structure
Here's what is included:

- [Agent](./Agent/readme.md) A self-hosted agent for Azure DevOps. You will need this because the built-in agents have a timeout of 1 hour.
- [GitHub Actions](./.github/workflows/README.md) GitHub Actions pipeline to deploy both Shared Services & MS-VDI in Azure environment. All the required Azure environment should be added to GitHub secrets.
- [Config](./Config) The configuration used when running the toolkit. This tells the toolkit where to store audit logs.
- [Docs](./Docs) Documentation for using the toolkit.
- [Environments](./Environments) These are sample reference architectures that can be deployed with the toolkit. They are sometimes decomposed into _archetypes_ and _landing zones_. A landing zone represents the portion of the reference architecture that is centrally managed. The archetype is the application specific infrastructure. The json files here are used by the toolkit to deploy the environments. The pipeline.yml files are for use with Azure DevOps; they are not needed if you are deploying locally.
- [LabVM](./LAbVM/readme.md) This provides a click-to-deploy experience for setting up the toolkit on a VM in Azure. The VM has all of the dependencies installed for the toolkit.
- [Modules](./Modules) Modules are the building blocks for the reference architectures. An indvidual module is an Azure Reousrce Manager template for deploying a single resource or a set of closely related resources. These modules are structured in a way to facilitate passing outputs to subsequent deployments.
- [Orchestration](./Orchestration) This folder contains the scripts for the toolkit. The primary entry point is `Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1`. This script is used for local deployments and by the sample Azure DevOps pipelines.
- [Scripts](./Scripts) These are additional assets that are used when deploying some of the environments.

