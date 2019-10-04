# Design Principles

These design principles drive the decisions around the toolkit's features and architecture.
Understanding the design principles is helpful for understanding the intended usage of the toolkit.

Contributors should be familar with these principles before submiting a pull request or recommending a new feature.

There are some instances where the current implementation is not consistent with the stated design principles. 
However, the intent to always improve consistency.

## Everything-as-Code, Declarative, and Automated

The toolkit is following the common [principles of DevOps](https://docs.microsoft.com/azure/architecture/checklist/dev-ops).

We place an emphasis on [infrastructure-as-code (IaC)](https://en.wikipedia.org/wiki/Infrastructure_as_code) following a [declarative approach](https://en.wikipedia.org/wiki/Declarative_programming). This principle is extended to policy and process (i.e., gated release process).
**Anything that can be managed through code, should be managed in code.** This is what is meant by _everything-as-code_.

The declarative model means that the code describes a _desired state_ and that some run-time is responsible for interpreting the code and establishing the desire state. A declarative approach is contrasted against an imperative or procedural approach. An imperative approach provides a set of steps to execute and a desired state can only be infer (at best) from the steps. Azure Resource Manager templates and Azure Policy are declarative.

Automation is a third pillar along with everything-as-code and the declarative approach.
Any change of state should be initiated as a change to source code. The change in source code triggers an automated process, that includes validation and safety checks. This allows for more predictable outcomes and reduces the risk of human error.
**Anything that can be automated, should be automated.**

## Don't abstract the platform

The toolkit should avoid introducing abstractions that encapsulate the native platform.
Instead, it should leverage native features and existing technologies as much as possible.

Any custom code included in the toolkit should be use to compose (or "glue together") native features.

## Open technology choices

A core purpose for the toolkit is to provide end-to-end reference implementations for core enterprise control plane scenarios. The reference implementations are concrete implementations and we have to choose specific technologies. While we have chosen native Azure technologies for our reference implementations, we recognize that customers may have other technology preferences. 

The toolkit should avoid designs that introduce [tight coupling](https://en.wikipedia.org/wiki/Loose_coupling) between different functions. For example, the technology used to orchestrate a deployment (i.e., Azure DevOps, Jenkins) should not restrict the technology used to define the deployment (i.e., Azure Resource Manager templates, Terraform).

## Common tools for automation and manual process

Any automatation should follow the same steps and use the same tools that a developer would use manually.
For example, a CI/CD pipeline in Azure DevOps should invoke the same commands that a human being would use when deploying manually.
By having common tools and prodcedures, outcomes are more predictable.
