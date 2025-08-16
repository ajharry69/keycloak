# --- Workload Identity Federation (Securely connect GitHub Actions to GCP) ---
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions-pool-keycloak"
  display_name              = "GitHub Actions (Keycloak)"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-keycloak"
  display_name                       = "GitHub Actions (Keycloak)"
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
