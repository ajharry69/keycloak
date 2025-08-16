# --- GKE Cluster (Autopilot) ---
resource "google_container_cluster" "primary" {
  name       = "keycloak-cluster"
  location   = var.gcp_region
  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # Autopilot automatically manages nodes and scaling.
  enable_autopilot    = true
  deletion_protection = false

  # Ensure Workload Identity is explicitly enabled
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}
