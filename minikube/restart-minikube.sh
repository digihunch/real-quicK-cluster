#! /bin/bash

# Exit when any command fails
set -e

# Check version history https://kubernetes.io/releases/
KUBE_VERSION=v1.24.3

# node size of the cluster to create
NODE_COUNT=3

# containerd is the standard CRI 
CRI=containerd

# Install hyperkit for x86
CPU_ARCH=$(uname -m)
if [[ $CPU_ARCH == "x86_64" ]]; then
  echo "You are on x86 CPU architecture. Minikube will use the preferred driver (hyperkit)."
  DRIVER=hyperkit
elif [[ $CPU_ARCH == "arm64" ]]; then
  printf '[Warning]'
  echo "You are on arm64 CPU architecture. Minikube cannot install the preferred driver (hyperkit). However, we can instead install Docker driver, which has a limitation. You will not have access to metallb's load balancer IP directly from command console."
  read -r -p "If you have Docker Desktop installed and running. Do you wish to contine? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
        echo "Checking if docker CLI and daemon are running"
        docker ps > /dev/null
        ;;
    *)
        exit 0
        ;;
  esac
  DRIVER=docker
else
   echo "Unsupported CPU architecture."
   exit 1;
fi

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

if [[ $DRIVER == "docker" ]]; then
  echo The docker driver uses bridge networking and does not support host networking. Therefore you cannot access the ingress IP from your command terminal.
  echo You can however, spin up a troubleshooting container on the same bridge network and access ingress IP from there. For example:
  echo docker run -it --net host nicolaka/netshoot 
fi
echo to destroy this cluster, run 
echo minikube stop --profile=$PROFILE_NAME && minikube delete --profile=$PROFILE_NAME
