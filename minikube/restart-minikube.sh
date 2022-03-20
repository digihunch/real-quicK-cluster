#! /bin/bash

KUBE_VERSION=v1.23.4
NODE_COUNT=3
CRI=containerd



minikube stop
minikube delete
minikube start --memory=12288 --cpus=6 --kubernetes-version=$KUBE_VERSION --nodes $NODE_COUNT --container-runtime=$CRI --driver=hyperkit --disk-size=150g
minikube addons enable metallb
MINIKUBE_IP=$(minikube ip)
expect << _EOF_
spawn minikube addons configure metallb
expect "Enter Load Balancer Start IP:" { send "${MINIKUBE_IP%.*}.16\\r" }
expect "Enter Load Balancer End IP:" { send "${MINIKUBE_IP%.*}.23\\r" }
expect eof
_EOF_
