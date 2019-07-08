#!/bin/bash

SUBSCRIPTION_ID='00000000-0000-0000-0000-000000000000'
TENANT_ID='00000000-0000-0000-0000-000000000000'
CLIENT_ID='00000000-0000-0000-0000-000000000000'
CLIENT_SECRET='00000000-0000-0000-0000-000000000000'
RESOURCE_GROUP_NAME='vsts-agent-rg'

az account set --subscription $SUBSCRIPTION_ID

RESOURCE_GROUP=$(az group exists --name $RESOURCE_GROUP_NAME)

if [ "$RESOURCE_GROUP" = false ]; then
    echo 'Creating resource group'
    az group create --name $RESOURCE_GROUP_NAME --location westus
else 
    echo 'Resource group already exists'
fi

export ARM_CLIENT_ID=$ARM_CLIENT_ID
export ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_TENANT_ID=$TENANT_ID
export IMAGE_NAME='ubuntu-self-hosted-agent'
export ARM_RESOURCE_GROUP=$RESOURCE_GROUP_NAME
export ARM_RESOURCE_LOCATION=westus

echo 'Packer will build an image'
packer build Ubuntu-1804.json 