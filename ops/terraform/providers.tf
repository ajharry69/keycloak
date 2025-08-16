terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "xently"

    workspaces {
      name = "keycloak"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}