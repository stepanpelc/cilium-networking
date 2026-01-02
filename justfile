CA_DIR := "./cilium-clustermesh-ca"
NS := "cilium"
EAST_CTX := "kind-cluster-east"
WEST_CTX := "kind-cluster-west"

default:
    @just --list

cluster-build cluster:
    kind create cluster --name cluster-{{cluster}} --config kind/kind-cluster-{{cluster}}.yaml

cluster-delete-all:
    just cluster-delete east
    just cluster-delete west

cluster-delete cluster:
    kind delete clusters cluster-{{cluster}}

cilium-install cluster:
    # kubectl --context kind-cluster-{{cluster}} create namespace cilium
    helm upgrade --install cilium cilium/cilium \
    --namespace cilium \
    --create-namespace \
    --version 1.18.1 \
    --set k8sServiceHost=$(kubectl get node --context  kind-cluster-{{cluster}} -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}') \
    -f values/cilium-{{cluster}}-values.yaml \
    --kube-context kind-cluster-{{cluster}}

cilium-uninstall cluster:
    helm delete cilium --namespace cilium --kube-context kind-cluster-{{cluster}}

cilium-validate cluster:
    cilium status -n cilium --context kind-cluster-{{cluster}} --wait
    kubectl -n cilium get pods --context kind-cluster-{{cluster}} -l k8s-app=cilium
    cilium connectivity test -n cilium --context kind-cluster-{{cluster}}
    kubectl delete ns cilium-test-1 --context kind-cluster-{{cluster}}

cilium-validation-delete cluster:
    kubectl delete ns cilium-test-1 --context kind-cluster-{{cluster}}

workload-deploy cluster:
    kubectl apply --context kind-cluster-{{cluster}} -f manifests/workload-{{cluster}}.yaml

cilium-status cluster:
    cilium status -n cilium --context kind-cluster-{{cluster}} --wait

cilium-status-all:
    just cilium-status west
    just cilium-status east

cilium-prepare-secret:
    kubectl --context kind-cluster-west create namespace cilium --dry-run=client -o yaml | kubectl apply -f -
    kubectl --context kind-cluster-west get secret -n cilium cilium-ca -o yaml | kubectl --context kind-cluster-east create -f -

cilium-status-mesh cluster:
    cilium clustermesh status -n cilium --context kind-cluster-{{cluster}} --wait

cilium-build-mesh:
    cilium clustermesh connect -n cilium --context kind-cluster-west --destination-context kind-cluster-east

cilium-delete-mesh:
    cilium clustermesh disconnect -n cilium --context kind-cluster-west --destination-context kind-cluster-east

cilium-hubble cluster:
    kubectl -n cilium port-forward svc/hubble-ui --context kind-cluster-{{cluster}} 8080:80

kubectl-use cluster:
    kubectl config use-context kind-cluster-{{cluster}}

k9s cluster:
    k9s --context kind-cluster-{{cluster}}

policy-deploy cluster policy:
    kubectl apply --context kind-cluster-{{cluster}} -f manifests/policy-{{policy}}.yaml

build-all:
    just cluster-build west
    just cluster-build east
    just cilium-install west
    just cilium-prepare-secret
    just cilium-install east
    just cilium-status east
    just cilium-build-mesh
    just cilium-status-mesh west

deploy-all:
    just workload-deploy west
    just workload-deploy east