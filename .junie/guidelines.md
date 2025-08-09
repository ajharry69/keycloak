Project: Keycloak Ops (Kubernetes Manifests + Image)

Audience: Advanced platform/devops engineers working with kustomize, `kubectl`, and container build tooling.

1. Build and Configuration
    - Image build
        - Multi-stage `Dockerfile` builds an optimized Keycloak image and embeds TLS material from `server.crt.pem` and
          `server.key.pem` into `/opt/keycloak/conf/`.
        - ARG `TAG` defaults to `26.3.1` and is reused for the runtime stage.
        - Local build: `docker build -t ghcr.io/ajharry69/keycloak:26.3.1 .`
        - Push: `docker push ghcr.io/ajharry69/keycloak:26.3.1`.
        - `Makefile` shortcuts: `make build-images` and `make build-and-push-images`.
    - Kubernetes deployment via kustomize
        - Base: `k8s/base` contains `Namespace`, `StatefulSet` (keycloak), Services, and persistence (Postgres
          Deployment/Service + PVCs).
        - Overlays:
            - development: adds plaintext Secret (`keycloak-credentials`), a `LoadBalancer` Service, and a patch that
              switches to start-dev and sets hostname/cert paths for local-ish testing.
            - production: expects ExternalSecrets (from a `ClusterSecretStore` named `gcp-secret-store`) and patches
              resources (replicas/resources).
        - Apply using kubectl kustomize integration: `make k8s-dev` / `make k8s-production` (`kubectl apply -k ...`).
          Delete with corresponding `-delete` targets.
    - Secrets
        - development overlay provides `keycloak-credentials` as stringData for convenience. DO NOT reuse beyond dev.
        - production overlay uses `external-secrets.io`. Prerequisite: deploy External Secrets Operator and configure a
          `ClusterSecretStore` named `gcp-secret-store` that maps to a desired cloud project.
    - Hostname and TLS
        - Base sets KC_HOSTNAME to https://oauth.xently.co.ke and `KC_HTTP_ENABLED=true` with `KC_PROXY=edge`. For
          non-production, the development overlay relaxes hostname strictness and provides cert/key file paths from the
          baked image (`/opt/keycloak/conf/server.crt.pem` and `/opt/keycloak/conf/server.key.pem`).
        - In production, terminate TLS at the ingress/edge unless you explicitly enable pod-level TLS; keep
          `KC_PROXY=edge` and ensure the external hostname is correct.
    - Storage
        - PVCs: `keycloak-pvc` (for Keycloak data) and `keycloak-db-pvc` (for Postgres). Ensure a default `StorageClass`
          is available or define an explicit `storageClassName`.
    - Database
        - Postgres 17-alpine Deployment in base for simplicity. For real production, replace with a managed database or
          a proper HA `StatefulSet` and update `KC_DB_URL` accordingly.

2. Additional Development Information
    - Repository layout conventions
        - Keep all generic manifests in `k8s/base` and environment-specific changes in `k8s/overlays/<env>`.
        - Use consistent labels: app: keycloak for app selection and service matching; app: `keycloak-database` for
          `Postgres`.
        - Avoid hardcoding public hostnames in base; prefer overlays to adjust `KC_HOSTNAME` and strictness flags.
    - Patching patterns
        - Use patches files in overlays to change container args, env, resources, and replicas. Keep patches minimal and
          environment-specific.
        - For secrets, development overlay may include simple Secret manifests; production should rely on External
          Secrets or cloud KMS-backed mechanisms.
    - Probes and ports
        - Maintain health endpoints on port 9000 (mgmt): `/health/started`, `/health/ready`, `/health/live`.
        - Service should expose 8080 (http), 8443 (https), 9000 (mgmt). Ingress/LB mapping belongs in overlays.
    - Storage and data safety
        - StatefulSet mounts keycloak-pvc at `/opt/keycloak/data`. Ensure RWO storage availability; consider RWX where
          appropriate and supported.
    - Image expectations
        - The image has `KC_HEALTH_ENABLED`, `KC_METRICS_ENABLED`, `KC_DB=postgres` baked in the Dockerfile.
        - Development overlay maps cert files via env to the baked-in `/opt/keycloak/conf/`. If you replace certs,
          rebuild the image.
    - Common pitfalls
        - Forgetting to create keycloak namespace before apply: included automatically via `base/namespace.yaml` when
          applying overlays.
        - Missing `StorageClass`: PVCs will remain Pending; define `storageClassName` where needed.
        - `ExternalSecrets` prerequisites are absent in the cluster: production overlay will not reconcile
          `keycloak-credentials`.
        - `KC_HOSTNAME` mismatch: issuer URLs and redirects will fail if the hostname does not reflect the external
          access method; ensure your Ingress and `KC_HOSTNAME` align.
    - Style
        - YAML with 2-space indentation; group related resources with '---' separators inside multi-doc files. Keep
          resource ordering stable to minimize diff noise.

Appendix: Useful commands

- Show Make targets: `make help`
- Apply dev overlay: `make k8s-dev`
- Delete dev overlay: `make k8s-dev-delete`
