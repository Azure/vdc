#!/bin/bash

SUBSCRIPTION_ID='00000000-0000-0000-0000-000000000000'
TENANT_ID='00000000-0000-0000-0000-000000000000'
CLIENT_ID='00000000-0000-0000-0000-000000000000'
CLIENT_SECRET='00000000-0000-0000-0000-000000000000'
RESOURCE_GROUP_NAME='vdc-azuredevops-agents-rg'

az login -u $CLIENT_ID -p $CLIENT_SECRET --service-principal --tenant $TENANT_ID

az account set --subscription $SUBSCRIPTION_ID

RESOURCE_GROUP=$(az group exists --name $RESOURCE_GROUP_NAME)

if [ "$RESOURCE_GROUP" = false ]; then
    echo 'Creating resource group'
    az group create --name $RESOURCE_GROUP_NAME --location westus
else 
    echo 'Resource group already exists'
fi

export ARM_CLIENT_ID=$CLIENT_ID
export ARM_CLIENT_SECRET=$CLIENT_SECRET
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_TENANT_ID=$TENANT_ID
export IMAGE_NAME='ubuntu-self-hosted-agent'
export ARM_RESOURCE_GROUP=$RESOURCE_GROUP_NAME
export ARM_RESOURCE_LOCATION='westus'
export VM_SIZE='Standard_DS2_v2'
export OS_DISK_SIZE=30

echo 'Packer will build an image'
packer build ubuntu-1804.json 