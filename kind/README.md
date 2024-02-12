

```sh
kind create cluster --config=kind-config.yaml
```

The node status is NotReady. Install Cilium:
```sh
cilium install --version 1.15.0
```

Wait for the node status to become ready. Then install MetalLB:

```sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
```



```sh
docker network inspect kind --format '{{json .IPAM.Config}}' | jq -r '.[0].Subnet'
```
From this CIDR, determine the IP range of load balancers. For example, if CIDR is 172.18.0.0/16, then use range 172.18.255.200-172.18.255.250


```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lb
  namespace: metallb-system
EOF
```

Create a deployment and expose it as an LB service: 

```sh
kubectl create deployment hello-test --image=kicbase/echo-server:1.0
kubectl expose deployment hello-test --type=LoadBalancer --port=8080


LB_IP=$(kubectl get svc/hello-test -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

```

```sh
docker run -it --net host nicolaka/netshoot
docker run --network=kind -it nicolaka/netshoot
```

curl $LB_IP:80
