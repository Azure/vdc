# Virtual Machine - Resource Manager (ARM) Template considerations
* Owner: Jorge Cotillo (jcotillo@microsoft.com)
* Reviewers: Virtual Datacenter (VDC) Team
* Status: Draft, revision 1.0

## Abstract
When building Resource Manager (ARM) templates for Virtual Machines, one common approach to account for template reusability is the following:

 1. One ARM template containing a Virtual Machine resource (including Network Interfaces)
 2. Different ARM templates to encrypt the Virtual Machine, install custom extensions, install Microsoft Monitoring Agent, etc.
 3. These different templates are referenced as `linked templates` in a master template

Using `linked templates` requires these templates to be either:

 1. Located on a site with public access or
 2. Located in an Azure Storage Account inside a public container or in a private container accessed using a SAS Token or Access Key

When updating one of the linked templates, a developer must have a process in place that after pushing an update to the source code repository, this update gets reflected in the public site or in the Azure Storage Account container, otherwise subsequent deployments might have unexpected results.

From the reusability stand point, having a master Virtual Machine template and multiple templates that accounts for custom extensions, installation of agents, etc. is a good approach.

### Goals
Provide reusability of templates without the use of linked templates and have the VDC Toolkit engine to pass deployment outputs between module deployments, in this case Virtual Machine resource Ids.

### Non-goals
NA

## Proposal
- Have one single master Virtual Machine template (one for Windows and Linux distros, the template will expose a virtualMachineOSType parameter that accepts either Windows or Linux values), this template will include default extensions such as Guest Policies, Log Analytics, Diagnostic, Antimalware and Network Watcher.
- Have multiple templates to account for Virtual Machine encryption or installation of Active Directory Domain Services (ADDS) or installation of Internet Information Services (IIS), etc, all these templates will be exposed as Modules.
- The Virtual Machine module will output Virtual Machine resource Ids as an array type and this output will be passed to the installation modules.

### VDC toolkit engine changes
The proposed change does not impact the current engine implementation. This proposed change has an impact on the _Virtual Machine modules_.

## References:
- https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates

[^1]: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates

