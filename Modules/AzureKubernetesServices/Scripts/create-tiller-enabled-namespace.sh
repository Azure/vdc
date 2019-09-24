#!/usr/bin/env bash

# This needs to be run with k8s cluster-admin role

PGM=$(basename $0)
DIR=$(dirname $0)

#
# Function to create tiller enabled namespace
# Parameters:
#   tiller namespace
#   path to kubeconfig file
function createTillerNamespace {

# This is a pre-req for running helm init
# for global or namespace-scoped tiller
# instances
#
# Naming convention indicates if this is 
# global or scoped.  
#
# If the namespace is "tiller", then the
# assumption is this is a global single
# global (cluster-wide) instance and will
# be granted the cluster-admin role.
#
# Otheriwse the assumption is that it's a
# instance scoped to a namespace
if [[ "$#" -ne 2 ]];then
    echo "$PGM usage namespace path-to-kubeconfig-file"
    exit 1
fi
local TARGET_NAMESPACE=$1
local KUBECONFIG_FILE=$2

echo "$PGM: Starting with TARGET_NAMESPACE:$TARGET_NAMESPACE KUBECONFIG_FILE:$KUBECONFIG_FILE"
# This could be replaced with more specific role
TILLER_RBAC_ROLE=cluster-admin

if [[ $TARGET_NAMESPACE == "tiller" ]];then
  echo "$PGM: Creating namespace for global tiller instance:$TARGET_NAMESPACE"
  BINDING_TYPE=ClusterRoleBinding
  BINDING_NAMESPACE='#'
else
  echo "$PGM: Creating namespace for scoped tiller instance:$TARGET_NAMESPACE"
  TILLER_NAMESPACE=$TARGET_NAMESPACE-tiller
  BINDING_TYPE=RoleBinding
  BINDING_NAMESPACE="namespace: $TARGET_NAMESPACE"
fi 

# If this is not a tiller global namspace, then create the target
# namespace first as this will be the target of the role grant to tiller
if [[ $TARGET_NAMESPACE != "tiller" ]];then
APPLY_NS_RESULT=$(cat <<EOF | KUBECONFIG=$KUBECONFIG_FILE kubectl apply -f - 
apiVersion: v1
kind: Namespace
metadata:
  name: $TARGET_NAMESPACE
---  
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $TARGET_NAMESPACE
  namespace: $TARGET_NAMESPACE
EOF
)
rc=$?
if  [[ rc -ne 0 ]];then
  echo "$PGM: Error creating target (non-tiller) namespace:$APPLY_NS_RESULT"
  exit 1
fi
echo "$PGM: Created target (non-tiller) namespace:$TARGET_NAMESPACE"
fi 

echo "$PGM: Granting tiller rights to target namespace:$TARGET_NAMESPACE"
APPLY_RESULT=$(cat <<EOF | KUBECONFIG=$KUBECONFIG_FILE kubectl apply -f - 
apiVersion: v1
kind: Namespace
metadata:
  name: $TILLER_NAMESPACE
---  
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: $TILLER_NAMESPACE
---
kind: $BINDING_TYPE
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $TILLER_NAMESPACE-$TILLER_RBAC_ROLE
  $BINDING_NAMESPACE
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: $TILLER_NAMESPACE
roleRef:
  kind: ClusterRole
  name: $TILLER_RBAC_ROLE
  apiGroup: rbac.authorization.k8s.io
EOF
)
rc=$?
if  [[ rc -ne 0 ]];then
  echo "$PGM: Error creating namespace:$APPLY_RESULT"
  exit 1
fi

# For non-global tiller, it (it's service account) needs 
# RBAC rights to it's own namespace to be able to 
# store configuration data in secrets/config maps
if [[ $TARGET_NAMESPACE != "tiller" ]];then
echo "$PGM: Granting non-global tiller rights in it's own namespace:$TILLER_NAMESPACE"
APPLY_RESULT=$(cat <<EOF | KUBECONFIG=$KUBECONFIG_FILE kubectl apply -f - 
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $TILLER_NAMESPACE-$TILLER_RBAC_ROLE
  namespace: $TILLER_NAMESPACE
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: $TILLER_NAMESPACE
roleRef:
  kind: ClusterRole
  name: $TILLER_RBAC_ROLE
  apiGroup: rbac.authorization.k8s.io
EOF
) 
rc=$?
if  [[ rc -ne 0 ]];then
  echo "$PGM: Error creating namespace:$APPLY_RESULT"
  exit 1
fi
fi # end of if not global tiller
}