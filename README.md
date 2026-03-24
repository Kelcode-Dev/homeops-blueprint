# HomeOps Blueprint

A production-ready, 4-tier GitOps blueprint for immutable Kubernetes homelabs. This repository is the companion template for the **HomeOps** series on [kelcode.co.uk](https://kelcode.co.uk).

## The 4-Tier Architecture

This repository follows a strict separation of concerns to prevent "YAML spaghetti" and ensure clean dependency management:

* **Clusters**: The entry point for Flux. Contains environment-specific sync manifests and Kustomization overlays
* **Infrastructure**: Core platform services (Networking, Ingress, Cert-Manager, Storage). These are the "foundational" services that apps rely on
* **Apps**: User-facing applications and services (Harbor, Nextcloud, etc.)
* **Databases**: Stateful backend services managed via operators (Postgres, Redis)

## The Golden Rule: Secrets First

**Do not run the Flux bootstrap command immediately.** This repository uses **SOPS** with **Age** for encryption. If you bootstrap Flux before providing the cluster with your private decryption key, the reconciliation loop will fail as it attempts to decrypt your infrastructure secrets.

### Step 1: Generate your Age Key
Generate a new Age key pair on your local machine. Keep the private key file (`age.agekey`) safe and **never** commit it to Git:
```bash
age-keygen -o age.agekey
```

### Step 2: Inject the Key into the Cluster
Create the `flux-system` namespace and manually insert the private key. This allows the Flux Kustomize controller to decrypt your `.sops.yaml` files immediately upon bootstrap:
```bash
kubectl create namespace flux-system
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=age.agekey
```

### Step 3: Configure Encryption Metadata
Update the `age` field in the root `.sops.yaml` with your **public** key. This tells the `sops` CLI which key to use for future encryption tasks.

### Step 4: Bootstrap the Fleet
Once your secrets are encrypted and pushed to your own Git repository, trigger the Flux bootstrap:
```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=homeops-blueprint \
  --branch=main \
  --path=./clusters/template-cluster \
  --personal
```

## Transparent Templates
This repository provides "transparent" secret templates (e.g., `cloudflare-token.yaml`). To use them:
1. Paste your real credentials into the `.yaml` file
2. Run `sops --encrypt --in-place path/to/secret.yaml`
3. Rename the file to `secret.sops.yaml` and commit

## Continuous Integration
This blueprint includes GitHub Actions (v6) to maintain cluster health:
* **Lint & Validate**: Ensures every manifest is syntactically correct and passes a `flux build` dry-run
* **Flux Diff**: (Requires self-hosted runner) Previews exactly what changes a Pull Request will make to the live cluster state
