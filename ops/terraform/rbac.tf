# --- Kubernetes RBAC managed by Terraform ---
# Grants cluster-admin to the GitHub Actions deploy Service Account inside the GKE cluster.

# Access token for the current Google provider identity (used to auth to the cluster)
data "google_client_config" "default" {}

# Lookup the cluster connection details after creation
# Ensures the data source waits until the GKE cluster resource exists
# before configuring the Kubernetes provider
data "google_container_cluster" "this" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
}

# Configure Kubernetes provider to talk to the GKE cluster
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_cluster_role_binding" "github_actions_cluster_admin" {
  metadata {
    name = "github-actions-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = google_service_account.github_actions_sa.email
    api_group = "rbac.authorization.k8s.io"
  }
}
