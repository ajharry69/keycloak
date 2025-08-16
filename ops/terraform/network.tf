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
