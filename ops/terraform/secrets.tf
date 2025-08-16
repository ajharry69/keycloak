# --- Google Secret Manager: Secrets for Keycloak ---
resource "google_secret_manager_secret" "kc_admin_user" {
  secret_id  = "keycloak-keycloak-admin-user"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "kc_admin_user_v" {
  secret      = google_secret_manager_secret.kc_admin_user.id
  secret_data = var.kc_admin_username
}

resource "google_secret_manager_secret" "kc_admin_password" {
  secret_id  = "keycloak-keycloak-admin-password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "kc_admin_password_v" {
  secret      = google_secret_manager_secret.kc_admin_password.id
  secret_data = var.kc_admin_password
}

resource "google_secret_manager_secret" "kc_db_user" {
  secret_id  = "keycloak-keycloak-db-user"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "kc_db_user_v" {
  secret      = google_secret_manager_secret.kc_db_user.id
  secret_data = var.kc_db_username
}

resource "google_secret_manager_secret" "kc_db_password" {
  secret_id  = "keycloak-keycloak-db-password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "kc_db_password_v" {
  secret      = google_secret_manager_secret.kc_db_password.id
  secret_data = var.kc_db_password
}
