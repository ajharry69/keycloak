# Keycloak Ops (Kubernetes Manifests + Image)

[![Keycloak](https://github.com/ajharry69/keycloak/actions/workflows/keycloak.yml/badge.svg?branch=main)](https://github.com/ajharry69/keycloak/actions/workflows/keycloak.yml)

## Introduction

This repository contains:

- A multi-stage [Dockerfile](Dockerfile) to build an optimized Keycloak image with health/metrics enabled and TLS
  materials baked in.
- Kubernetes manifests organized with `kustomize`, including a base and two overlays (**development**, **production**).
- A [Makefile](Makefile) with convenient build and deploy targets.

Audience: Advanced platform/devops engineers working with `kustomize`, `kubectl`, and container build tooling.

## Overview

- Image registry/name: `ghcr.io/ajharry69/keycloak`
- Default Keycloak version TAG (ARG): `26.3.1`
- Health endpoints exposed on management port 9000: `/health/started`, `/health/ready`, `/health/live`
- Base uses a `StatefulSet` for Keycloak and a simple Postgres 17-alpine Deployment for persistence

## Repository Layout

```
.
├── Dockerfile                 # Multi-stage, embeds TLS assets into /opt/keycloak/conf/
├── Makefile                   # build and k8s apply/delete helpers
├── k8s/
│   ├── base/                  # Namespace, StatefulSet (keycloak), Services, and persistence (Postgres + PVC)
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── workloads.yaml     # Keycloak StatefulSet
│   │   ├── services.yaml      # 8080/8443/9000; headless discovery service
│   │   └── persistence/
│   │       ├── workloads.yaml # Postgres StatefulSet (with volumeClaimTemplates)
│   │       └── services.yaml  # Postgres Service
│   └── overlays/
│       ├── development/       # start-dev, relaxed hostname, LB Service, plaintext Secret
│       └── production/        # ExternalSecrets + resource/replica patches
├── server.crt.pem             # Baked into image for dev/test
└── server.key.pem             # Baked into image for dev/test
```

Keep all generic manifests in `k8s/base` and environment-specific changes in `k8s/overlays/<env>`.

## Image Build

The Dockerfile builds an optimized Keycloak image and copies TLS material to `/opt/keycloak/conf/`.

- Build: `make build-images`
- Push: `make build-and-push-images`

If you replace the TLS certs, rebuild the image so that the development overlay picks up the new files.

## Quickstart

1) Build the image (optional if you pull from [GHCR](https://github.com/ajharry69/keycloak/pkgs/container/keycloak)):
    - `make build-images`
    - Optionally push: `make build-and-push-images`

2) Deploy development overlay:
    - `make k8s`
    - Wait for the `keycloak` StatefulSet Pod to become Ready.
    - If your cluster supports `LoadBalancer`, note the external IP of `Service/keycloak-loadbalancer`.

3) Access Keycloak:
    - Dev: https via the LB or via cluster DNS: `https://keycloak.keycloak.svc.cluster.local` (dev overlay config).
    - Admin credentials (dev): see [k8s/overlays/development/secrets.yaml](k8s/overlays/development/secrets.yaml) (
      **_admin_**/**_admin_** by default, not for **production**).

4) Cleanup:
    - `make k8s-delete`

## Common Pitfalls & Troubleshooting

- Namespace is missing: Applying an overlay includes [base/namespace.yaml](k8s/base/namespace.yaml), so the `keycloak`
  namespace will be created automatically.
- Pending PVCs: Ensure a default `StorageClass` exists or set `storageClassName` on PVCs where required.
- External Secrets prerequisites are missing: The production overlay will not reconcile `keycloak-credentials` without
  the External Secrets Operator and a configured `ClusterSecretStore` named `gcp-secret-store`.
- Hostname mismatch: Authentication redirects and issuer URLs will fail if `KC_HOSTNAME` does not reflect the external
  access method. Align Ingress host with `KC_HOSTNAME`.
- Certificates in development: If you change `server.crt.pem`/`server.key.pem`, rebuild the image.
- Database connectivity: Verify `keycloak-database` Service DNS and that credential exists in the `keycloak-credentials`
  Secret.

## Style & Conventions

- YAML uses 2-space indentation.
- Group related resources with `---` separators in multi-doc YAML files.
- Keep resource ordering stable to minimize diff noise.

## Useful Commands

- Show make targets: `make help`
- Apply dev overlay: `make k8s`
- Delete dev overlay: `make k8s-delete`
- Apply prod overlay: `make k8s-production`
- Delete prod overlay: `make k8s-production-delete`

## Upgrading Keycloak

- To use a different Keycloak version, build with `--build-arg TAG=<version>` and bump your image tag accordingly, e.g.:
    - `docker build --build-arg TAG=26.1.3 -t ghcr.io/ajharry69/keycloak:26.1.3 .`
    - Update references in manifests or pull the desired tag.

## License

See [LICENSE](LICENSE) for details.