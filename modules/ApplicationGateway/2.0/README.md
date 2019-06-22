**Table of Contents**
- [Application Gateway 2.0](#Application-Gateway-20)
  - [Resources](#Resources)
  - [Prerequisites](#Prerequisites)
    - [Azure virtual network dedicated subnet](#Azure-virtual-network-dedicated-subnet)
    - [Certificate for SSL termination](#Certificate-for-SSL-termination)
    - [Log Analytics workspace](#Log-Analytics-workspace)
  - [Parameters](#Parameters)
    - [Parameter `applicationGatewayName`](#Parameter-applicationGatewayName)
    - [Parameter `sku`](#Parameter-sku)
    - [Parameter `capacity`](#Parameter-capacity)
    - [Parameter `http2Enabled`](#Parameter-http2Enabled)
    - [Parameter `publicIPAllocationIdleTimeoutInMinutes`](#Parameter-publicIPAllocationIdleTimeoutInMinutes)
    - [Parameter `vNetName`](#Parameter-vNetName)
    - [Parameter `subnetName`](#Parameter-subnetName)
    - [Parameter `vNetResourceGroup`](#Parameter-vNetResourceGroup)
    - [Parameter `vNetSubscriptionId`](#Parameter-vNetSubscriptionId)
    - [Parameter `frontendPrivateIPAddress`](#Parameter-frontendPrivateIPAddress)
    - [Parameter `sslBase64CertificateData`](#Parameter-sslBase64CertificateData)
    - [Parameter `sslCertificatePassword`](#Parameter-sslCertificatePassword)
    - [Parameter `backendPools`](#Parameter-backendPools)
    - [Parameter `backendHttpConfigurations`](#Parameter-backendHttpConfigurations)
    - [Parameter `frontendHttpsListeners`](#Parameter-frontendHttpsListeners)
    - [Parameter `frontendHttpRedirects`](#Parameter-frontendHttpRedirects)
    - [Parameter `routingRules`](#Parameter-routingRules)
    - [Parameter `logAnalyticsWorkspaceResourceId`](#Parameter-logAnalyticsWorkspaceResourceId)
  - [Outputs](#Outputs)
  - [Secrets](#Secrets)
  - [Considerations](#Considerations)
  - [Additional resources](#Additional-resources)

# Application Gateway 2.0

[Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/overview) is a web traffic load balancer that enables you to manage traffic to your web applications. Traditional load balancers operate at the transport layer (OSI layer 4 - TCP and UDP) and route traffic based on source IP address and port, to a destination IP address and port.

With Application Gateway, you can make routing decisions based on additional attributes of an HTTP request, such as URI path or host headers. For example, you can route traffic based on the incoming URL. This type of routing is known as application layer (OSI layer 7) load balancing. Azure Application Gateway can do URL-based routing and more.

## Resources

The following Resource Providers will be deployed:

| Resource Provider | API Version
| - | -
| [Microsoft.Network/publicIPAddresses](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/publicipaddresses) | 2017-08-01
[Microsoft.Network/applicationGateways](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/applicationgateways) | 2018-12-01

## Prerequisites

### Azure virtual network dedicated subnet

A [dedicated subnet](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet) is required for the application gateway

The identity deploying the module must have the following [RBAC actions](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftnetwork) allowed on this subnet:

```json
"Actions": [
    Microsoft.Network/virtualNetworks/subnets/join/action	
]
```

### Certificate for SSL termination

An [SSL certificate](https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview#ssl-termination) is required to be added to the HTTPS listener to enable the application gateway to derive a symmetric key as per SSL protocol specification. The symmetric key is then used to encrypt and decrypt the traffic sent to the gateway. For this service, **the SSL certificate needs to be in base64 format**.

For the SSL connection to work, you need to ensure that the SSL certificate meets the following conditions:
+ That the current date and time is within the "Valid from" and "Valid to" date range on the certificate.
+ That the certificate's "Common Name" (CN) matches the host header in the request. For example, if the client is making a request to `https://www.contoso.com/`, then the CN must be `www.contoso.com`.

Application gateway supports the following types of certificates:
+ **CA (Certificate Authority) certificate**: A CA certificate is a digital certificate issued by a certificate authority (CA)
+ **EV (Extended Validation) certificate**: An EV certificate is an industry standard certificate guidelines. This will turn the browser locator bar green and publish company name as well.
+ **Wildcard Certificate**: This certificate supports any number of subdomains based on *.site.com, where your subdomain would replace the *. It doesn’t, however, support site.com, so in case the users are accessing your website without typing the leading "www", the wildcard certificate will not cover that.
+ **Self-Signed certificates**: Client browsers do not trust these certificates and will warn the user that the virtual service’s certificate is not part of a trust chain. Self-signed certificates are good for testing or environments where administrators control the clients and can safely bypass the browser’s security alerts. Production workloads should never use self-signed certificates.

You can create a self-signed certificate in base64 that can be used in Application Gateway by using PowerShell:

```PowerShell
# This Script requires the PowerShell module "pkiclient" - which is not compatible with PowerShell Core - and administrator privileges

$certStoreLocation = "cert:\LocalMachine\My"
$pwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
$pfxFilePath = "C:\mypfx.pfx"

#Create a self-signed SSL server certificate in the computer MY store with the subject alternative name set to www.fabrikam.com, www.contoso.com and Subject and Issuer name set to www.fabrikam.com expiring in 120 months (10 years)
$thumbprint = (New-SelfSignedCertificate -DnsName "www.fabrikam.com", "www.contoso.com" -CertStoreLocation $certStoreLocation -NotAfter (Get-Date).AddMonths(120)).Thumbprint

$cerPath = Join-Path $certStoreLocation $thumbprint
Get-ChildItem -Path $cerPath | Export-PfxCertificate -FilePath $pfxFilePath -Password $pwd | Out-null

$bytesCert = Get-Content $pfxFilePath -Encoding Byte
$base64Cert = [System.Convert]::ToBase64String($bytesCert) 
```

### Log Analytics workspace

A [log analytics workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/azure-networking-analytics#azure-application-gateway-and-network-security-group-analytics) where [Diagnostics Logs](https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-diagnostics#diagnostic-logging) and [Metrics](https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-diagnostics#metrics) will be sent.

The identity deploying the module must have the following [RBAC actions](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftoperationalinsights) allowed on this resource:

```json
"Actions": [
    "Microsoft.OperationalInsights/workspaces/sharedKeys/read",
    "Microsoft.OperationalInsights/workspaces/sharedKeys/action",
    "Microsoft.OperationalInsights/workspaces/read"
]
```

## Parameters

### Parameter `applicationGatewayName`

The name to be used for the Application Gateway version 1 resource

Type: `string`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/overview

### Parameter `sku`

The name of the SKU Name of the v1 Application Gateway to be configured

Type: `string`

Default value: `WAF_Medium`

Allowed Values:
+ `Standard_Small`
+ `Standard_Medium`
+ `Standard_Large`
+ `WAF_Medium`
+ `WAF_Large`

Related info:
+ https://azure.microsoft.com/en-us/pricing/details/application-gateway/

### Parameter `capacity`

The number of Application Gateway instances to be configured

Type: `int`

Default value: `2`

Allowed Values : `1` - `10`

Related info:
+ https://azure.microsoft.com/en-us/pricing/details/application-gateway/

### Parameter `http2Enabled`

Enables HTTP/2 support

Type: `bool`

Default value: `true`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#http2-support

### Parameter `publicIPAllocationIdleTimeoutInMinutes`

The maximum allowed idle time in minutes for Public IP allocation

Type: `int`

Default value: `10`

Allowed Values: `4` - `30`
 
### Parameter `vNetName`

The name of the Virtual Network where the Application Gateway will be deployed

See the prerequisites section to understand the permissions needed for this parameter

Type: `string`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet

### Parameter `subnetName`

The name of Gateway Subnet Name where the Application Gateway will be deployed

See the prerequisites section to understand the permissions needed for this parameter

Type: `string`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet


### Parameter `vNetResourceGroup`

The name of the Virtual Network Resource Group where the Application Gateway will be deployed. If empty, the current Resource Group name will be chosen

See the prerequisites section to understand the permissions needed for this parameter

Type: `string`

Default value: `[resourceGroup().name]`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet

### Parameter `vNetSubscriptionId`

The Subscription Id of the Virtual Network where the Application Gateway will be deployed. If empty, the current Subscription Id will be chosen

See the prerequisites section to understand the permissions needed for this parameter

Type: `string`

Default value: `[subscription().subscriptionId]`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet

### Parameter `frontendPrivateIPAddress`

The private IP within the Application Gateway subent to be used as frontend private address

The IP must be available in the configured subnet. If empty, allocation method will be set to dynamic. Once a method (static or dynamic) has been configured, it cannot be changed

Type: `string`

### Parameter `sslBase64CertificateData`

The SSL base64-coded Certificate that will be used to configure the HTTPS listeners

See the prerequisites section to understand the permissions needed for this parameter

Type: `securestring`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview
+ https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ssl-powershell#create-a-self-signed-certificate
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#protocol

### Parameter `sslCertificatePassword`

The password of the SSL base64-coded Certificate that will be used to configure the HTTPS listeners

See the prerequisites section to understand the permissions needed for this parameter

Type: `securestring`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview
+ https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ssl-powershell#create-a-self-signed-certificate
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#protocol

### Parameter `backendPools`

The backend pools to be configured

Type: `array`

Allowed Values:
+ 

Schema:
```json
[
    {
        "backendPoolName": "String. The name to be given to the backend pool. It must be unique across backend pools",
        "backendAddresses": [
            {
                "ipAddress": "String. Choose between property 'ipAddress' or property 'fqdn'. The IP address to be used for the health probe request. E.g.: 10.0.0.1",
                "fqdn": "String. Choose between property 'ipAddress' or property 'fqdn'. The fqdn to be used for the health probe request. E.g.: appservice.azurewebsites.net"
            }
        ]
    }
]
```

Example:
```
[
    {
        "backendPoolName": "appServiceBackendPool",
        "backendAddresses": [
            {
                "fqdn": "aghapp.azurewebsites.net"
            }
        ]
    },
    {
        "backendPoolName": "privateVmBackendPool",
        "backendAddresses": [
            {
                "ipAddress": "10.0.0.4"
            }
        ]
    }
]
```

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#back-end-pool

### Parameter `backendHttpConfigurations`

The backend HTTP settings to be configured. These HTTP settings will be used to rewrite the incoming HTTP requests for the backend pools

Type: `array`

Schema:
```json
[
    {
        "backendHttpConfigurationName": "String. The name to be given to the backend HTTP setting. It must be unique across backend HTTP settings",
        "port": "Integer. The port to be used for the HTTP request to the backend pools. Integer",
        "protocol": "String. Allowed values: [http, https]. The port to be used for the HTTP request to the backend pools",
        "cookieBasedAffinity": "String. Allowed values: [Disabled, Enabled]. The port to be used for the HTTP request to the backend pools",
        "pickHostNameFromBackendAddress": "Boolean. True if the host header in the request should be set to the host name of the backend pool (IP or FQDN). This is helpful in the scenarios where the domain name of the backend is different from the DNS name of the application, such as in a scenario where Azure App Service is used as backend",
        "probeEnabled": "Boolean. If a defined probe should be used to check the health of the backend pool",
        "healthProbe": {
            "host": "String. The host name or IP address to be used for the health probe request. E.g.: appservice.azurewebsites.net",
            "path": "String. The path to append to the host name for the health probe request. It must start by '/'. E.g.: /",
            "statusCodes": [
                "Integer. HTTP response codes that will make the probe to be considered as healthy. E.g.: [200, 201]"
            ]
        }
    }
]
```

Example:
```
[
    {
        "backendHttpConfigurationName": "appServiceBackendHttpsSetting",
        "port": 443,
        "protocol": "https",
        "cookieBasedAffinity": "Disabled",
        "pickHostNameFromBackendAddress": true,
        "probeEnabled": true,
        "healthProbe": {
            "host": "aghapp.azurewebsites.net",
            "path": "/",
            "statusCodes": [
                "200"
            ]
        }
    },
    {
        "backendHttpConfigurationName": "privateVmHttpSetting",
        "port": 80,
        "protocol": "http",
        "cookieBasedAffinity": "Disabled",
        "pickHostNameFromBackendAddress": false,
        "probeEnabled": true,
        "healthProbe": {
            "host": "10.0.0.4",
            "path": "/",
            "statusCodes": [
                "200",
                "401"
            ]
        }
    }
]
```

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#http-settings

### Parameter `frontendHttpsListeners`

The frontend https listeners to be configured

Type: `array`

Schema:
```json
[
    {
        "frontendListenerName": "String. The name to be given to the frontend listener. It must be unique across listeners",
        "frontendIPType": "String. Allowed values: [public | private]. The frontend IP to be used for the listener",
        "port": "Integer. The port to be configured in the HTTPS listener. Ports must be unique across listeners"
    }
]
```

Example:
```
[
    {
        "frontendListenerName": "public443",
        "frontendIPType": "Public",
        "port": 443
    },
    {
        "frontendListenerName": "private443",
        "frontendIPType": "Private",
        "port": 4433
    }
]
```

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#listeners

### Parameter `frontendHttpRedirects`

The http redirects to be configured. Each redirect will route http traffic to a pre-defined frontEnd https listener

Type: `array`

Default value: `[]`

Schema:
```json
[
    {
        "frontendIPType": "String. Allowed values: [public | private]. The frontend IP to be used for the listener",
        "port": "Integer. The port to be configured in the HTTP listener. Ports must be unique across listeners",
        "frontendListenerName": "String. The name of an existing frontend listener where the HTTP requests will be redirected"
    }
]
```

Example:
```
[
    {
        "frontendIPType": "Public",
        "port": 80,
        "frontendListenerName": "public443"
    },
    {
        "frontendIPType": "Private",
        "port": 8080,
        "frontendListenerName": "private443"
    }
]
```

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#redirection-setting

### Parameter `routingRules`

The routing rules to be configured. These rules will be used to route requests from frontend listeners to backend pools using a backend HTTP configuration

Type: `array`

Schema:
```json
[
    {
        "frontendListenerName": "String. The name of an existing frontend listener where the requests will be received",
        "backendPoolName": "String. The name of an backend pool where the requests will be routed to",
        "backendHttpConfigurationName": "String. The name of the backend HTTP configuration that will be used to rewrite the HTTP requests"
    }
]
```

Example:
```
[
    {
      "frontendListenerName": "public443",
      "backendPoolName": "appServiceBackendPool",
      "backendHttpConfigurationName": "appServiceBackendHttpsSetting"
    },
    {
      "frontendListenerName": "private443",
      "backendPoolName": "privateVmBackendPool",
      "backendHttpConfigurationName": "privateVmHttpSetting"
    }
]
```

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#request-routing-rules

### Parameter `logAnalyticsWorkspaceResourceId`

The resource Id of the Log Analytics workspace where logs and metrics will be sent

See the prerequisites section to understand the permissions needed for this parameter

Type: `string`

Default value: `""`

Related info:
+ https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-diagnostics#diagnostic-logging
+ https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-diagnostics#metrics

## Outputs

This module does not have any output

## Secrets

This module does not create any secret

## Considerations

+ This module will deploy the Application Gateway version 1 resource
+ Only HTTPS frontend Listeners will be configured. An option to redirect HTTP traffic to HTTPS listeners is offered as an option

## Additional resources

- [What is Azure Application Gateway?](https://docs.microsoft.com/en-us/azure/application-gateway/overview)
- [Application Gateway pricing](https://azure.microsoft.com/en-us/pricing/details/application-gateway/)
- [Azure virtual network and dedicated subnet](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#azure-virtual-network-and-dedicated-subnet)
- [Overview of SSL termination and end to end SSL with Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/ssl-overview)
- [Configure SSL termination with Key Vault certificates by using Azure PowerShell](https://docs.microsoft.com/en-us/azure/application-gateway/configure-keyvault-ps)
- [Application Gateway configuration overview](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview)
- [Back-end health, diagnostic logs, and metrics for Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-diagnostics)


