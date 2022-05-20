#!/usr/bin/env bash

kind create cluster --config kind-calico.yaml
kubectl apply -f calico.yaml # modified pods CIDR and FELIX_EXTERNALNODESCIDRLIST
kubectl apply -f calico-adds.yaml
kubectl apply -f dns.yaml
kubectl -n kube-system rollout restart deployment coredns
kubectl apply -f pod.yaml
kubectl apply -f bgp.yaml


docker exec kind-b-control-plane curl -L https://github.com/projectcalico/calico/releases/download/v3.23.1/calicoctl-linux-amd64 -o /usr/bin/calicoctl
docker exec kind-b-control-plane chmod +x /usr/bin/calicoctl
docker exec kind-b-control-plane curl -L https://github.com/projectcalico/bird/releases/download/v0.3.2/birdcl -o /usr/bin/birdcl
docker exec kind-b-control-plane chmod +x /usr/bin/birdcl


docker exec kind-b-control-plane calicoctl node status