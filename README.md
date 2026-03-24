# 🗺️ HomeOps Blueprint

[](https://www.google.com/search?q=https://github.com/Kelcode-Dev/homeops-blueprint/actions)
[](https://opensource.org/licenses/MIT)
[](https://fluxcd.io)
[](https://github.com/getsops/sops)

> ℹ️
> **Living Documentation**: This repository is developed in tandem with the **HomeOps** deep-dive series. For detailed walkthroughs on the logic behind this 4-tier architecture, head over to [kelcode.co.uk/tag/homeops](https://kelcode.co.uk/tag/homeops).

A production-ready, 4-tier GitOps blueprint for building immutable Kubernetes homelabs. This repository provides a standardised, modular architecture for managing everything from core networking to stateful database clusters.


## 🏛️ The 4-Tier Architecture

This blueprint enforces a strict separation of concerns to prevent configuration drift and simplify maintenance.

  * **`clusters/`** — The entry point for Flux. Contains cluster-specific sync manifests and Kustomization overrides
  * **`infrastructure/`** — Foundations (Networking, Ingress, Cert-Manager, Storage). Apps live or die based on this tier
  * **`apps/`** — User-facing services (Nextcloud, Harbor, etc.)
  * **`databases/`** — Stateful backends managed via CloudNativePG or other operators

## 📋 Prerequisites

Before you begin, ensure your local environment has the following tools installed:

  * [Flux CLI](https://fluxcd.io/flux/installation/) (v2.x+)
  * [SOPS](https://github.com/getsops/sops)
  * [age](https://github.com/FiloSottile/age)
  * [kubectl](https://kubernetes.io/docs/tasks/tools/)

## 🔐 The Golden Rule: Secrets First

**Do not run the bootstrap command immediately.** Because this repo uses **SOPS** with **Age** for encryption, Flux must have your private key *before* it tries to sync.

### 1. Generate your Age Key

```bash
age-keygen -o age.agekey
```

> [\!CAUTION]
> **Never commit `age.agekey` to Git.** If you lose this file, you lose access to your encrypted data.

### 2. Inject the Key into the Cluster

Create the namespace and manually insert the private key so Flux can decrypt your manifests during the first reconciliation.

```bash
kubectl create namespace flux-system
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=age.agekey
```

### 3. Update Encryption Metadata

Update the `public_key` in the root `.sops.yaml` with your new public key. This ensures all future `sops` commands use your specific key pair.

## 🚀 Deployment Guide

### 1. Initialise your Repository

If you are using this as a template, rename the placeholder directory to match your cluster's purpose:

```bash
mv clusters/template-cluster clusters/my-home-cluster
```

### 2. Prepare Environment Variables

You must provide Flux with a GitHub Personal Access Token (PAT) with `repo` permissions.

```bash
export GITHUB_TOKEN=ghp_your_token_here
export GITHUB_USER=your-github-username
```

### 3. Bootstrap the Fleet

Trigger the Flux bootstrap to link your cluster to this repository.

```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=homeops-blueprint \
  --branch=main \
  --path=clusters/my-home-cluster \
  --personal
```

### 4. Verify the Sync

Watch the reconciliation process. The infrastructure must be "Ready" before apps can successfully deploy.

```bash
flux get kustomizations --watch
```

## 🛡️ Security & CI

  * **Transparent Secrets**: Use `.secret.yaml` for raw data, then encrypt to `.sops.yaml`, alternatively encrypt in-place to reduce the risk of forgetting. Our `.gitignore` is configured to prevent accidental leaks
  * **Validation**: Every Pull Request triggers a `flux build` to verify Kustomize paths and YAML syntax

## 🔎 Troubleshooting

GitOps can be opaque when things go wrong. Use these commands to peel back the layers of the reconciliation loop.

### 1. The High-Level View
Start here to identify which tier is stalling. A `Ready: False` status on a Kustomization usually indicates a path error, a dependency bottleneck, or a SOPS decryption failure.
```bash
flux get kustomizations
# Or the shorthand version
flux get ks
```

### 2. Deep-Diving into Helm
If your Kustomizations are `Ready` but your applications are missing, the issue likely lies within the Helm controller. You must check both the **Release** (the deployment state) and the **Chart** (the source artifact).
```bash
# Check if the release is failing to install or upgrade
kubectl get helmrelease -A
# Check if the chart failed to pull from the repository
kubectl get helmchart -A
```

### 3. Reading the "Events"
When a resource is stuck, the `status` block in the Kubernetes events will tell you exactly why. This is where you will find "ImagePullBackOff" or "Secret not found" errors.
```bash
# Describe a specific Kustomization to see recent events
kubectl describe ks -n flux-system infrastructure
# Describe a failing HelmRelease to see the controller logs
kubectl describe hr -n tailscale tsop
```

### 4. Common Blockers
* **SOPS Decryption Failed**: Ensure your `sops-age` secret is in the `flux-system` namespace and contains the correct private key
* **Dependency Deadlock**: Check your `dependsOn` fields in the `flux-system` manifests; if `apps` depends on `infrastructure`, it will wait indefinitely if Traefik or Cert-Manager are unhealthy
* **Namespace Mismatch**: Verify that your `HelmRelease` metadata namespace matches the `namespace.yaml` provided in your base or overlay directories

### Immediate Actionable Tip
If you make a change and don't want to wait for the `interval` (e.g., 1h) to pass, you can force an immediate sync with `flux reconcile ks infrastructure --with-source`. This is the fastest way to verify a fix during active development.
