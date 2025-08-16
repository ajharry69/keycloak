variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources into."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the resources."
  type        = string
  default     = "africa-south1"
}

variable "github_repo" {
  description = "Your GitHub repository in 'owner/repo' format."
  type        = string
  default     = "xently/keycloak"
}

variable "eso_namespace" {
  description = "Kubernetes namespace where External Secrets Operator runs."
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account" {
  description = "Kubernetes ServiceAccount name used by External Secrets Operator."
  type        = string
  default     = "external-secrets"
}