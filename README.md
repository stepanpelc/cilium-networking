# Cilium networking sandbox

This repository provides a Justfile that automates the creation of a two-cluster Kubernetes environment using kind and Cilium, including ClusterMesh configuration, validation, and workload deployment.

The setup is designed for local development, testing, and demonstrations of Cilium multi-cluster networking.

---

## Scope

The Justfile manages the full lifecycle of

* kind-based Kubernetes clusters
* Cilium installation and validation
* Cilium ClusterMesh setup and teardown
* Workload and policy deployment
* Operational access using kubectl, k9s, and Hubble

The clusters are referred to as

* east
* west

---

## Requirements

All commands in the Justfile assume the following tools are installed and available in PATH.

### Required Tools

* just - Task runner used to execute all targets

* kind - Used to create and delete local Kubernetes clusters (Moby is required for running eBPF calls)

* kubectl - Kubernetes CLI, configured to work with kind clusters

* helm - Required for installing and managing Cilium

* cilium CLI - Required for validation, connectivity tests, and ClusterMesh operations

* k9s - Optional but required if using the `k9s` target

### Kubernetes and System Requirements

* Docker or a compatible container runtime supported by kind
* Sufficient system resources to run two Kubernetes clusters simultaneously
* Localhost ports 8080 available when using Hubble UI port-forwarding

---

## Repository Structure Assumptions

The Justfile assumes the following files and directories exist.

* `kind/`

  * `kind-cluster-east.yaml`
  * `kind-cluster-west.yaml`

* `values/`

  * `cilium-east-values.yaml`
  * `cilium-west-values.yaml`

* `manifests/`

  * `workload-east.yaml`
  * `workload-west.yaml`
  * `policy-<name>.yaml`

The exact content of these files is not enforced by the Justfile but is required for successful execution.

---

## Default Target

* `default`
  Displays all available Just targets
  Equivalent to running `just --list`

---

## Cluster Lifecycle Targets

* `cluster-build <cluster>`
  Creates a kind cluster named `cluster-<cluster>` using
  `kind/kind-cluster-<cluster>.yaml`

* `cluster-delete <cluster>`
  Deletes the specified kind cluster

* `cluster-delete-all`
  Deletes both east and west clusters

---

## Cilium Installation and Removal

* `cilium-install <cluster>`
  Installs or upgrades Cilium using Helm
  Characteristics

  * Namespace `cilium` is created automatically
  * Cilium version is pinned to `1.18.1`
  * `k8sServiceHost` is dynamically resolved from the kind node InternalIP
  * Cluster-specific values are loaded from `values/cilium-<cluster>-values.yaml`

* `cilium-uninstall <cluster>`
  Uninstalls Cilium from the specified cluster

---

## Cilium Validation and Status

* `cilium-validate <cluster>`
  Runs a full validation sequence

  * Waits for Cilium readiness
  * Lists Cilium pods
  * Runs `cilium connectivity test`
  * Deletes the test namespace after completion

* `cilium-validation-delete <cluster>`
  Deletes the connectivity test namespace manually

* `cilium-status <cluster>`
  Displays and waits for Cilium status

* `cilium-status-all`
  Runs `cilium-status` on both clusters

---

## ClusterMesh Management

* `cilium-prepare-secret`
  Prepares ClusterMesh trust by

  * Ensuring the `cilium` namespace exists on west
  * Copying the `cilium-ca` secret from west to east

* `cilium-build-mesh`
  Establishes ClusterMesh connectivity from west to east

* `cilium-delete-mesh`
  Disconnects the ClusterMesh between west and east

* `cilium-status-mesh <cluster>`
  Displays ClusterMesh status for the specified cluster

---

## Workloads and Policies

* `workload-deploy <cluster>`
  Deploys workloads from `manifests/workload-<cluster>.yaml`

* `policy-deploy <cluster> <policy>`
  Applies a policy from `manifests/policy-<policy>.yaml`

---

## Operational Access and Observability

* `cilium-hubble <cluster>`
  Port-forwards the Hubble UI service
  Accessible at `http://localhost:8080`

* `kubectl-use <cluster>`
  Switches the current kubeconfig context to the specified cluster

* `k9s <cluster>`
  Launches k9s using the cluster’s kubeconfig context

---

## High-Level Automation Targets

* `build-all`
  Fully bootstraps the environment

  * Creates both clusters
  * Installs Cilium on west
  * Prepares ClusterMesh secrets
  * Installs Cilium on east
  * Validates east cluster
  * Builds ClusterMesh
  * Verifies mesh status on west

* `deploy-all`
  Deploys workloads on both clusters

---

## Typical Usage Flow

* Bootstrap everything
  `just build-all`

* Deploy workloads
  `just deploy-all`

* Check ClusterMesh health
  `just cilium-status-mesh west`

* Tear down the environment
  `just cluster-delete-all`

---

## Notes

* The Justfile assumes consistent naming between kind clusters, kubeconfig contexts, and configuration files
* Error handling is delegated to the underlying tools
* The setup is intended for local development and testing, not production use

---

This README is intended to be kept in sync with the Justfile and can serve as both operational documentation and onboarding material.
