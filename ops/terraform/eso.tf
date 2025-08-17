# --- External Secrets Operator (GSA + WI binding) ---
resource "google_service_account" "eso_gsm" {
  account_id   = "eso-gsm"
  display_name = "External Secrets Operator - GSM Access"
}

# Allow ESO to read secrets from Secret Manager
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = google_service_account.eso_gsm.member
}

# Least-privilege access: grant ESO GSA accessor on specific GSM secrets managed in this stack
resource "google_secret_manager_secret_iam_member" "eso_access_admin_user" {
  secret_id = google_secret_manager_secret.kc_admin_user.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.eso_gsm.member
}

resource "google_secret_manager_secret_iam_member" "eso_access_admin_password" {
  secret_id = google_secret_manager_secret.kc_admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.eso_gsm.member
}

resource "google_secret_manager_secret_iam_member" "eso_access_db_user" {
  secret_id = google_secret_manager_secret.kc_db_user.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.eso_gsm.member
}

resource "google_secret_manager_secret_iam_member" "eso_access_db_password" {
  secret_id = google_secret_manager_secret.kc_db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.eso_gsm.member
}

# Bind KSA (external-secrets/external-secrets) to the GSA via Workload Identity
resource "google_service_account_iam_member" "eso_wi_binding" {
  service_account_id = google_service_account.eso_gsm.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.eso_namespace}/${var.eso_service_account}]"
}
