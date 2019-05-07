#!/usr/bin/env bash

DIR=$(dirname $0)
PGM=$(basename $0)

if [[ "$1" == "" ]];then
    echo "$PGM: usage namespace"
    exit 1
fi
TILLER_NAMESPACE=$1
KEY_VAULT_NAME=$2
CA_CERT_NAME=$3

HELM_CA=helm
TILLER_CA=tiller
if [[ $TILLER_NAMESPACE != "tiller" ]];then
    HELM_CA=${TILLER_NAMESPACE}-$HELM_CA
    TILLER_CA=${TILLER_NAMESPACE}-$TILLER_CA
fi
echo "$PGM: Creating helm cert with CA:$HELM_CA"
#$DIR/../infra/create-sign-w-x509-and-upload-cert.sh "$@" $HELM_CA
$DIR/create-sign-w-x509-and-upload-cert.sh central-tst-rbac $HELM_CA $KEY_VAULT_NAME $CA_CERT_NAME
echo "$PGM: Creating tiller cert with CA:$TILLER_CA"
#$DIR/../infra/create-sign-w-x509-and-upload-cert.sh "$@" $TILLER_CA "IP:127.0.0.1"
$DIR/create-sign-w-x509-and-upload-cert.sh central-tst-rbac $TILLER_CA $KEY_VAULT_NAME $CA_CERT_NAME "IP:127.0.0.1"
