#! /bin/bash

# Exit when any command fails
set -e

# Check version history https://kubernetes.io/releases/
KUBE_VERSION=v1.29.0

# node size of the cluster to create
NODE_COUNT=3

# containerd is the standard CRI 
CRI=containerd


# Custom minikube profile
PROFILE_NAME=rqc

read -r -p "Press Y if you have Docker Desktop running and wish to contine installing Minikube with Docker driver? [y/N] " response
case "$response" in
  [yY][eE][sS]|[yY]) 
      echo "Checking if docker CLI and daemon are running"
      docker ps > /dev/null
      ;;
  *)
      exit 0
      ;;
esac

# set CNI to cilium. latest version is up to minikube 
CNI=auto

read -r -p "Do you want to use Cilium as CNI? [y/N] " response
case "$response" in
  [yY][eE][sS]|[yY])
    echo "setting CNI to cilium"
    CNI=cilium
    ;;
  *)
    exit 0
    ;;
esac


# if the minikube profile already exists, then stop and delete the cluster first
minikube profile list --output=table | awk -F'[| ]' '{print $3}' | awk '!/Profile|---------/' | grep ^$PROFILE_NAME$ && minikube stop --profile=$PROFILE_NAME && minikube delete --profile=$PROFILE_NAME

# start the cluster under the specified profile name
minikube start --profile=$PROFILE_NAME --memory=12288 --cpus=3 --disk-size=150g --kubernetes-version=$KUBE_VERSION --nodes $NODE_COUNT --container-runtime=$CRI --driver=$DRIVER --cni=$CNI
minikube addons enable metrics-server --profile=$PROFILE_NAME


echo ---  With Docker driver on Mac the virtual network is not addressable from the host. As a result, you cannot connect to Ingress IP from command terminal. However, you can tunnel the traffic from host with the following command from a separate terminal window:
echo ---  minikube tunnel --profile="$PROFILE_NAME"
echo ---  Then the external IP of load balancer service is tunneled to the host. To destroy this cluster after testing, run: 
echo ---  minikube stop --profile=$PROFILE_NAME "&&" minikube delete --profile=$PROFILE_NAME
