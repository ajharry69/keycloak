# --- Project Data ---
data "google_project" "current" {}

# --- VPC Network ---
resource "google_compute_network" "vpc_network" {
  name                    = "keycloak-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "keycloak-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.gcp_region
}

# --- GKE Cluster (using Autopilot for simplicity and cost-effectiveness) ---
resource "google_container_cluster" "primary" {
  name       = "keycloak-cluster"
  location   = var.gcp_region
  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # Autopilot automatically manages nodes and scaling.
  enable_autopilot = true
  deletion_protection = false

  # Ensure Workload Identity is explicitly enabled
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

# --- Service Account for GitHub Actions to use for deployment ---
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-deployer"
  display_name = "GitHub Actions Deployer SA"
}

# --- IAM Permissions for the Service Account ---
# Allow SA to push to Artifact Registry
resource "google_project_iam_member" "artifact_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Allow SA to manage the GKE cluster
resource "google_project_iam_member" "gke_developer" {
  project = var.gcp_project_id
  role    = "roles/container.developer" # Provides necessary access to deploy to GKE
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
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

# --- Workload Identity Federation (Securely connect GitHub Actions to GCP) ---
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  attribute_condition                = "assertion.repository=='${var.github_repo}'"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# --- External Secrets Operator (GSA + WI binding) ---
resource "google_service_account" "eso_gsm" {
  account_id   = "eso-gsm"
  display_name = "External Secrets Operator - GSM Access"
}

# Allow ESO to read secrets from Secret Manager
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso_gsm.email}"
}

# Bind KSA (external-secrets/external-secrets) to the GSA via Workload Identity
resource "google_service_account_iam_member" "eso_wi_binding" {
  service_account_id = google_service_account.eso_gsm.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.eso_namespace}/${var.eso_service_account}]"
}