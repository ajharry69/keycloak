# --- Service Account for GitHub Actions to use for deployment ---
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-keycloak"
  display_name = "GitHub Actions Keycloak SA"
}

# --- IAM Permissions for the Service Account ---
# Allow SA to push to Artifact Registry
resource "google_project_iam_member" "artifact_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = google_service_account.github_actions_sa.member
}

# Allow SA to manage the GKE cluster
resource "google_project_iam_member" "gke_developer" {
  project = var.gcp_project_id
  role    = "roles/container.developer" # Provides necessary access to deploy to GKE
  member  = google_service_account.github_actions_sa.member
}

resource "google_project_iam_member" "cluster_role_binding" {
  project = var.gcp_project_id
  role    = "container.clusterRoleBindings.create"
  member  = google_service_account.github_actions_sa.member
}

# Grant default node service account the default container node role to avoid degraded operations
resource "google_project_iam_member" "node_sa_container_default" {
  project = var.gcp_project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# Recommended: allow nodes to write logs/metrics for HPA and observability
resource "google_project_iam_member" "node_sa_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "node_sa_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "node_sa_stackdriver" {
  project = var.gcp_project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}
