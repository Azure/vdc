# Documentation

- [Understanding the concepts](understand/readme.md)
  - [Prerequisite Azure knowledge](understand/azure.md) - Resources for understanding the Azure services that the toolkit utilizes.
  - [Understanding the Automation Toolkit](understand/toolkit.md) - Explains the important concepts in the toolkit.
  - [Understanding environment types](understand/environment-types.md) - Describes the built-in environment types that the toolkit can deploy.
  - [Common workflow](understand/workflow.md) - Covers the typical usage pattern for the tools in the toolkit.
  - [Roles and permissions](understand/roles.md) - Lists the custom roles that are provided by default in the toolkit.
  - [Modules](understand/modules.adoc) - Explains the modules included in the toolkit.

- [Setting up the toolkit](setup/readme.md)
  - [Run the Docker image](setup/setup-docker.md) (Recommended) - How to setup the toolkit using Docker.
  - [Run on your local machine](setup/setup-local.md) - How to setup the toolkit natively.

- [Usage patterns for the toolkit](use/readme.md)
  - [Your first deployment](use/your-first-deployment.md) - Quick start tutorial for deploying the _simulated on-premises archetype_.
  - [General considerations](use/general-considerations.md) - Items to evaluate before deploying any archetype.
  - [Creating archetype configuration files](use/configuration-files.adoc) - How to prepare an `archetype.json` file.
    - [Common parameters](use/common-parameters.adoc) - Parameters used in all archetype configuration files.
    - [Common workload parameters](use/common-workload-config.adoc) - Parameters used by workload archetype configuration files.
  - [Archetype deployment considerations](use/archetype-deployment-considerations.md) - Items to evaluate that are specific to _shared-services_ and _workload_ environments.
  - [Validating deployments](use/deployment-validation.adoc) - How to validate an archetype configuration.

- [Extending the toolkit](extend/readme.md)
  - [Creating new modules](extend/creating-new-modules.adoc) - How to create a new module.
  - [Creating new archetypes](extend/creating-new-archetypes.adoc) - How to create a new archetype.
  - [Using the integration tests](extend/integration-testing.adoc) - How to run and add new integration tests.

- [Script Reference](reference/readme.md)
  - [policy-assignment.py](reference/script-policy-assignment.adoc) Update subscription policy post-deployment
  - [role-creation.py](reference/script-role-creation.adoc) Create subscription roles
  - [subscription.py](reference/script-subscription.adoc) Create management groups and subscriptions
  - [vdc.py](reference/script-vdc.adoc) Deploy archetypes and modules

- [Archetypes](archetypes/readme.md)
  - [Simulated on-premises environment](archetypes/on-premises/overview.adoc)
  - [Shared services](archetypes/shared-services/overview.adoc)
  - [IaaS N-tier architecture](archetypes/ntier-iaas/overview.adoc)
  - [App Service Environment + SQL Database](archetypes/paas/overview.adoc)
  - [SAP HANA](archetypes/sap-hana/overview.adoc)
  - [Cloudbreak](archetypes/cloudbreak/overview.adoc)

> NOTE: If you are interested in contributing, please note that some of the docs are [authored in AsciiDoc](adoc-file-format.adoc) and not markdown.