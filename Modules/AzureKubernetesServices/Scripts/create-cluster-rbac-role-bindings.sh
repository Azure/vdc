#!/usr/bin/env bash

#
# - Creates binding for cluster-admin role
# - Creates role and binding for view-all custom cluster role 
#   which extends the default view role to allow view access 
#   to cluster resources (e.g. nodes, secret names [not content])
#
PGM=$(basename $0)
DIR=$(dirname $0)

CLUSTER_NAME=$1
CLUSTER_RG=$2
RBAC_CLUSTER_ADMIN_AD_GROUP=$3
RBAC_CLUSTER_VIEW_AD_GROUP=$4
RBAC_EXTEND_VIEW_CLUSTER_ROLE=$5
RBAC_ENABLE_READ_ONLY_DASHBOARD=$6


if [[ -z $RBAC_CLUSTER_ADMIN_AD_GROUP ]] && [[ -z $RBAC_CLUSTER_VIEW_ALL_AD_GROUP ]];then
    echo "$PGM: Neither RBAC_CLUSTER_ADMIN_AD_GROUP or RBAC_CLUSTER_VIEW_ALL_AD_GROUP are set.  Nothing to do."
    exit 0
fi

#CLUSTER_NAME=$ENV_NAME-k8s

echo "$PGM: Getting admin credentials for cluster:$CLUSTER_NAME"
TMP_KUBECONFIG=$(mktemp)
if [[ $rc -ne 0 ]];then
    echo "$PGM: Error creating temp file:$TMP_KUBECONFIG"
    exit 1
fi
function cleanup {
    echo "$PGM: Removing tmp file $TMP_KUBECONFIG ..."; 
    rm -f $TMP_KUBECONFIG; 
    echo "$PGM: Done removing tmp file"
}
trap cleanup EXIT

echo "$PGM: Using temp file:$TMP_KUBECONFIG for kubeconfig"
# get admin credentials
echo "$PGM: cluster rg: $CLUSTER_RG name: $CLUSTER_NAME"
AKS_ADMIN_CREDS=$(az aks get-credentials --admin -n $CLUSTER_NAME -g $CLUSTER_RG --file $TMP_KUBECONFIG)
rc=$?
if [[ $rc -ne 0 ]];then
    echo "$PGM: Error getting admin credentials:$AKS_ADMIN_CREDS"
    exit 1
fi
# bind AD Group to admin cluster role
# this should be for "break glass" access to the cluster
if [[ ! -z $RBAC_CLUSTER_ADMIN_AD_GROUP ]];then
echo "$PGM: Binding cluster role cluster-admin to AD Group:$RBAC_CLUSTER_ADMIN_AD_GROUP"
API_OBJECT=$(cat <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: aad-cluster-admin
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: "$RBAC_CLUSTER_ADMIN_AD_GROUP"
EOF
)
#ADMIN_BINDING_RESULT=$(kubectl create clusterrolebinding aad-cluster-admin \
#    --kubeconfig=$TMP_KUBECONFIG \
#    --clusterrole=cluster-admin \
#    --group=$RBAC_CLUSTER_ADMIN_AD_GROUP 2>&1
#)
ADMIN_BINDING_RESULT=$(kubectl apply --kubeconfig $TMP_KUBECONFIG -f <(echo "$API_OBJECT") 2>&1)
rc=$?
if [[ $rc -ne 0 ]];then
    echo "$PGM: Error creating cluster-admin binding: $ADMIN_BINDING_RESULT"
    exit 1
fi
fi # end create clsuter-admin binding

# bind AAD group to cluster view (read only role)
if [[ ! -z $RBAC_CLUSTER_VIEW_AD_GROUP ]];then
    if [[ $RBAC_EXTEND_VIEW_CLUSTER_ROLE == "Y" ]];then
        echo "$PGM: Extending view cluster role ..."
        EXTEND_VIEW_RESULT=$(kubectl apply --kubeconfig $TMP_KUBECONFIG -f $DIR/view-all-cluster-role.yaml 2>&1)
        rc=$?
        if [[ $rc -ne 0 ]];then
            echo "$PGM: Error extending view clusterrole: $EXTEND_VIEW_RESULT"
        exit 1
        fi
    else
        echo "$PGM: NOT extending view cluster role"
    fi
    echo "$PGM: Binding cluster role view to AD Group:$RBAC_CLUSTER_VIEW_AD_GROUP"
API_OBJECT=$(cat <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: aad-view
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: view
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: "$RBAC_CLUSTER_VIEW_AD_GROUP"
EOF
)
#VIEW_BINDING_RESULT=$(kubectl apply clusterrolebinding aad-view \
#    --kubeconfig=$TMP_KUBECONFIG \
#    --clusterrole=view \
#    --group=$RBAC_CLUSTER_VIEW_AD_GROUP 2>&1
#)
VIEW_BINDING_RESULT=$(kubectl apply --kubeconfig $TMP_KUBECONFIG -f <(echo "$API_OBJECT") 2>&1)     
rc=$?
if [[ $rc -ne 0 ]];then
    echo "$PGM: Error creating view binding:$VIEW_BINDING_RESULT"
    exit 1
else
    echo "$PGM: Cluster view binding created"
fi
fi # end create view binding

#
# If you want to allow internal access to the 
# kubernetes dashboard with RBAC enabled:
#
# 1. Grant service account read only rights to resources
# 2. Grant access to create proxy to dashboard
#
if [[ ! -z $RBAC_ENABLE_READ_ONLY_DASHBOARD ]];then
    echo "$PGM: Creating dashboard view clusterrole binding"
    DASHBOARD_NS=kube-system
    DASHBOARD_SA=kubernetes-dashboard
API_OBJECT=$(cat <<EOF
#
# Grant view access to the kubernetes dashboard
#
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
    name: dashboard-view-all
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: view
subjects:
  - kind: ServiceAccount
    name: ${DASHBOARD_SA}
    namespace: ${DASHBOARD_NS}
---
#
# This is needed to let users with "view"
# ClusterRole run the proxy.
#
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dashboard-proxy
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["kubernetes-dashboard"]
  verbs: ["get", "list", "watch"]
EOF
)
#
#DASHBOARD_BINDING_RESULT=$(kubectl apply clusterrolebinding dashboard-view-all \
#    --kubeconfig=$TMP_KUBECONFIG \
#    --clusterrole=view \
#    --serviceaccount=${DASHBOARD_NS}:${DASHBOARD_SA} 2>&1
#)
DASHBOARD_BINDING_RESULT=$(kubectl apply --kubeconfig $TMP_KUBECONFIG -f <(echo "$API_OBJECT") 2>&1)    
rc=$?
if [[ $rc -ne 0 ]];then
    echo "$PGM: Error creating dashboard view binding:$DASHBOARD_BINDING_RESULT"
    exit 1
else
    echo "$PGM: Dashboard view binding created"
fi
fi # end grant dashboard view