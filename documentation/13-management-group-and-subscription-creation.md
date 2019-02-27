# Launching the management group or subscription creation

To run the deployment script, you need to open a terminal/command line and
navigate to the root of the VDC Toolkit folder, or you can run the
preconfigured Docker image that starts at the correct script folder location.

Before beginning, you need to sign into the Azure CLI tool using the following
command:

>   *az login*

This prompts you to log in using the Azure web interface. 

Make sure to login with an account owner to be able to create Management groups and Subscriptions.

Once this is complete, you can launch a deployment from the
terminal/command-line interface by launching the
[subscription.py](../subscription.py)
script:

# Subscription commands

## Subscription creation

*[Linux/OSX]*

>   *python3 subscription.py create-subscription {arguments}*

*[Windows]:*

>   *py subscription.py create-subscription {arguments}*

*[Docker]:*

>   *python subscription.py create-subscription {arguments}*

## Arguments

There are several required and optional arguments that you can pass for a
deployment:

| **Argument**                             | **Description**                                                                                         |
|--------------------------------------|-----------------------------------------------------------------------------------------------------|
| \--subscription-name [Required]       | The name of the subscription to create                                                              |
| \--offer-type [Required]              | Azure's subscription offer type (i.e. MS-AZR-0017P)                                                 |
| \--billing-enrollment-name [Optional] | If not passed, the code will look for a default billing enrollment account name (first value found) |

## Associate subscription to management group 

*[Linux/OSX]*

>   *python3 subscription.py associate-management-group {arguments}*

*[Windows]:*

>   *py subscription.py associate-management-group {arguments}*

*[Docker]:*

>   *python subscription.py associate-management-group {arguments}*

## Arguments

There are several required and optional arguments that you can pass for a
deployment:

| **Argument**                         | **Description**                                                                              |
|----------------------------------|------------------------------------------------------------------------------------------|
| \--subscription-id [Required]     | The name of the subscription to createSubscription Id to associate to a management group |
| \--management-group-id [Required] | Management group Id                                                                      |

# Management group commands

## Management group creation

*[Linux/OSX]*

>   *python3 subscription.py create-management-group {arguments}*

*[Windows]:*

>   *py subscription.py create-management-group {arguments}*

*[Docker]:*

>   *python subscription.py create-management-group {arguments}*

## Arguments

There are several required and optional arguments that you can pass for a
deployment:

| **Argument**                       | **Description**                                                                                                                                                                                                                                                                                        |
|--------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \--id [Required]                | Management group Id                                                                                                                                                                                                                                                                                |
| \--subscription-id [Optional]   | If passed, the code will attempt to associate the subscription to the management group created                                                                                                                                                                                                     |
| \--subscription-name [Optional] | If passed, the code will attempt to associate the subscription (by looking the subscripton id by its name) to the management group created. Passing subscription-name will make an additional API call to retrieve the subscriptions based on the name, we recommend using subscription-id instead |
