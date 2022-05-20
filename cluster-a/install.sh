#!/usr/bin/env bash

kind create cluster --config kind-calico.yaml
kubectl apply -f calico.yaml # modified pods CIDR and FELIX_EXTERNALNODESCIDRLIST
kubectl apply -f calico-adds.yaml
kubectl apply -f dns.yaml
kubectl -n kube-system rollout restart deployment coredns
kubectl apply -f pod.yaml
kubectl apply -f bgp.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
kubectl apply -f pool.yaml

docker exec kind-a-control-plane curl -L https://github.com/projectcalico/calico/releases/download/v3.23.1/calicoctl-linux-amd64 -o /usr/bin/calicoctl
docker exec kind-a-control-plane chmod +x /usr/bin/calicoctl
docker exec kind-a-control-plane curl -L https://github.com/projectcalico/bird/releases/download/v0.3.2/birdcl -o /usr/bin/birdcl
docker exec kind-a-control-plane chmod +x /usr/bin/birdcl

docker exec kind-a-control-plane calicoctl node status
docker exec kind-a-control-plane ip r


helm repo add devtron http://helm.devtron.ai/
helm upgrade --install -n vpn --create-namespace openvpn devtron/openvpn --version 4.2.5 --values ./vpn-values.yaml


POD_NAME=$(kubectl get pods --namespace "vpn" -l "app=openvpn,release=openvpn" -o jsonpath='{ .items[0].metadata.name }')
SERVICE_NAME=$(kubectl get svc --namespace "vpn" -l "app=openvpn,release=openvpn" -o jsonpath='{ .items[0].metadata.name }')
SERVICE_IP=$(kubectl get svc --namespace "vpn" "$SERVICE_NAME" -o go-template='{{ range $k, $v := (index .status.loadBalancer.ingress 0)}}{{ $v }}{{end}}')
KEY_NAME=kubeVPN-a
kubectl --namespace "vpn" exec -it "$POD_NAME" -- /etc/openvpn/setup/newClientCert.sh "$KEY_NAME" "$SERVICE_IP"
kubectl --namespace "vpn" exec -it "$POD_NAME" -- cat "/etc/openvpn/certs/pki/$KEY_NAME.ovpn" > "$KEY_NAME.ovpn"