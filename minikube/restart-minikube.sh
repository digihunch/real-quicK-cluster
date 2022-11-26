#! /bin/bash

# Check version history https://kubernetes.io/releases/
KUBE_VERSION=v1.24.3

# node size of the cluster to create
NODE_COUNT=3

# containerd is the standard CRI 
CRI=containerd

# Install hyperkit for x86
CPU_ARCH=$(uname -m)
if [[ $CPU_ARCH == "x86_64" ]]; then
  DRIVER=hyperkit
elif [[ $CPU_ARCH == "arm64" ]]; then
  DRIVER=docker
else
   echo "Unsupported CPU architecture."
   exit 1;
fi

DRIVER=hyperkit    

# Custom minikube profile
PROFILE_NAME=rqc

# if the minikube profile already exists, then stop and delete the cluster first
minikube profile list --output=table | awk -F'[| ]' '{print $3}' | awk '!/Profile|---------/' | grep ^$PROFILE_NAME$ && minikube stop --profile=$PROFILE_NAME && minikube delete --profile=$PROFILE_NAME

# start the cluster under the specified profile name
minikube start --profile=$PROFILE_NAME --memory=12288 --cpus=3 --kubernetes-version=$KUBE_VERSION --nodes $NODE_COUNT --container-runtime=$CRI --driver=$DRIVER --disk-size=150g
minikube addons enable metallb --profile=$PROFILE_NAME
minikube addons enable metrics-server --profile=$PROFILE_NAME

# interactively configure load balancer IP range
MINIKUBE_IP=$(minikube ip --profile=$PROFILE_NAME)
expect << _EOF_
spawn minikube addons configure metallb --profile=$PROFILE_NAME
expect "Enter Load Balancer Start IP:" { send "${MINIKUBE_IP%.*}.16\\r" }
expect "Enter Load Balancer End IP:" { send "${MINIKUBE_IP%.*}.23\\r" }
expect eof
_EOF_
