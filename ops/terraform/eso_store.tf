# Manage ClusterSecretStore via Terraform so project ID is sourced from Terraform variables
# Requires the Kubernetes provider configured to connect to the GKE cluster (see rbac.tf)

resource "kubernetes_manifest" "cluster_secret_store_gcp" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "gcp-secret-store"
    }
    spec = {
      provider = {
        gcpsm = {
          # Use the project ID provided to Terraform
          projectID = var.gcp_project_id
        }
      }
    }
  }
}
