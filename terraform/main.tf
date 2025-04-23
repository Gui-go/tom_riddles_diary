# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define local values for reuse
locals {
  proj_id           = "tom-riddle-diary1"
  service_name      = "streamlit-ollama-service1"
  repo_id           = "repo"
  streamlit_image   = "us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit:latest"
  ollama_image      = "ollama/ollama:latest"
  sa_email          = "${local.service_name}-sa@${var.project_id}.iam.gserviceaccount.com"
  resource_limits = {
    streamlit = {
      cpu    = "2"
      memory = "4Gi"
    }
    ollama = {
      cpu    = "4"
      memory = "8Gi"
    }
  }
}

# Enable necessary APIs
resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Create a service account for the Cloud Run service
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${local.service_name}-sa"
  display_name = "Cloud Run Service Account"
  # Prevent conflicts if the service account already exists
  lifecycle {
    ignore_changes = [account_id]
  }
}

# Grant the service account the Cloud Run Invoker role
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${local.sa_email}"
}

resource "google_project_iam_member" "service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${local.sa_email}"
}

resource "google_project_iam_member" "service_account_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountCreator"
  member  = "serviceAccount:${local.sa_email}"
}

# resource "google_project_iam_member" "iam_policy_admin" {
#   project = var.project_id
#   role    = "roles/iam.policyAdmin"
#   member  = "serviceAccount:${local.sa_email}"
# }

# Example for Cloud Run Admin (if needed for creating Cloud Run services)
resource "google_project_iam_member" "cloud_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.sa_email}"
}

# Example for Artifact Registry Admin (if needed for creating AR repositories)
resource "google_project_iam_member" "artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${local.sa_email}"
}


####

# Create an Artifact Registry repository to store container images
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = local.repo_id
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry_api]
}

# Define the Cloud Run service with Streamlit (ingress) and Ollama (sidecar) containers
resource "google_cloud_run_v2_service" "streamlit_ollama_service" {
  name     = local.service_name
  location = var.region
  deletion_protection = false # Added to allow destruction of the service

  template {
    max_instance_request_concurrency = 80
    timeout                         = "3600s"
    containers {
      image = local.streamlit_image
      name  = "streamlit-container"
      ports {
        container_port = 8501
      }
      env {
        name  = "OLLAMA_HOST"
        value = "http://localhost:11434"
      }
      resources {
        limits = local.resource_limits.streamlit
      }
    }
    containers {
      image = local.ollama_image
      name  = "ollama-container"
      env {
        name  = "PORT"
        value = "11434"
      }
      command = ["/bin/sh"]
      args    = ["-c", "ollama serve & sleep 5 && ollama pull phi3 && wait"]
      resources {
        limits = local.resource_limits.ollama
      }
    }
    # service_account_name = local.sa_email
    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }
    annotations = {
      "run.googleapis.com/ingress" = "all"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_service.run_api,
    google_project_service.artifactregistry_api,
    google_artifact_registry_repository.repo
  ]
}

# Ensure unauthenticated access
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.streamlit_ollama_service.location
  service  = google_cloud_run_v2_service.streamlit_ollama_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the Cloud Run service URL
output "service_url" {
  value = google_cloud_run_v2_service.streamlit_ollama_service.uri
}

# Define variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}