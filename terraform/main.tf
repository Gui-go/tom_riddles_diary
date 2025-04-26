# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define local values for reuse
locals {
  proj_id           = "tom-riddle-diary1"
  region            = "us-central1"
  service_name      = "streamlit-ollama-service2"
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

resource "google_project_service" "cloudresourcemanager_api" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Create a service account for the Cloud Run service
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${local.service_name}-sa"
  display_name = "Cloud Run Service Account"
  lifecycle {
    ignore_changes = [account_id]
  }
  depends_on = [google_project_service.iam_api]
}

# Grant the service account the Cloud Run Invoker role
resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${local.sa_email}"
  depends_on = [google_project_service.cloudresourcemanager_api, google_service_account.cloud_run_sa]
}

# Grant additional roles to the GitHub Actions service account
resource "google_project_iam_member" "service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_iam_member" "service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_iam_member" "project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_iam_member" "artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_iam_member" "cloud_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
  depends_on = [google_project_service.cloudresourcemanager_api]
}

# Create an Artifact Registry repository to store container images
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = local.repo_id
  format        = "DOCKER"
  lifecycle {
    ignore_changes = [repository_id]
  }
  depends_on = [google_project_service.artifactregistry_api]
}

# Define the Cloud Run service with Streamlit (ingress) and Ollama (sidecar) containers
resource "google_cloud_run_v2_service" "streamlit_ollama_service" {
  name     = local.service_name
  location = var.region
  deletion_protection = false

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
      min_instance_count = 0
      max_instance_count = 2
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
    google_artifact_registry_repository.repo,
    google_service_account.cloud_run_sa
  ]
}

# Ensure unauthenticated access
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.streamlit_ollama_service.location
  service  = google_cloud_run_v2_service.streamlit_ollama_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
  depends_on = [google_project_service.cloudresourcemanager_api]
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