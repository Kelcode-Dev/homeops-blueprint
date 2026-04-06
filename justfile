set shell := ["bash", "-c"]

# Default recipe (runs if you just type 'just')
help:
    @just --list

## SOPS Workloads
# List all SOPS files found in the project
list-sops:
  @find . -name "*.sops.yaml" ! -name ".sops.yaml" | while read -r file; do \
    if grep -q "sops:" "$file"; then \
      printf "[\033[32mENC\033[0m] %s\n" "$file"; \
    else \
      printf "[\033[31mUNSAFE\033[0m] %s\n" "$file"; \
    fi; \
  done

# Encrypt all plain-text .sops.yaml files (Safety check)
encrypt-all:
  @find . -name "*.sops.yaml" ! -name ".sops.yaml" | while read -r file; do \
    if ! grep -q "sops:" "$file"; then \
      sops -e --in-place "$file" && echo "Encrypted $file"; \
    fi; \
  done

# Encrypt a specific secret (e.g., just encrypt database)
# usage: just encrypt <name> (without the .sops.yaml suffix)
encrypt name:
  sops -e --in-place {{name}}

# Decrypt a specific secret
decrypt name:
  sops -d --in-place {{name}}

## FLUX Worklods

# Reconcile a specific Flux Kustomization
# Usage: just sync talos-eternium
sync ks:
  flux reconcile kustomization {{ks}} --with-source

# Force a sync of all Flux resources immediately
reconcile:
  flux reconcile source git flux-system
  flux reconcile kustomization flux-system

# Watch the status of all Flux kustomizations
watch:
  watch flux get kustomizations

# Check if the cluster meets Flux requirements
check:
  flux check --pre

# Suspend a suspended kustomization
# Usage: just suspend <name>
suspend name:
  flux suspend kustomization {{name}}

# Resume a suspended kustomization
# Usage: just resume <name>
resume name:
  flux resume kustomization {{name}}

# Install the git pre-commit hook
install-hooks:
    @echo "Linking pre-commit hook..."
    @cp .githooks/pre-commit .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "Hook installed successfully"

# Generates a random 32-byte hex string and outputs the Authelia PBKDF2 digest
authelia-hash:
    #!/usr/bin/env bash
    set -e

    SECRET=$(openssl rand -hex 32)
    echo "Raw Secret: ${SECRET}"
    echo "Authelia Digest:"
    docker run --rm authelia/authelia:latest authelia crypto hash generate pbkdf2 --password "${SECRET}"
