# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 4.0"
#     }
#   }
# }

# # Define local values for reuse
locals {
  proj_id                     = "tom-riddle-diary1"
  proj_number                 = "911461992812"
  region                      = "us-central1"
  service_name                = "toms-service"
  vpc_connector_name          = "connector"
  vpc_network_name            = "net"
  vpc_subnetwork_name         = "subnet"
  vpc_subnetwork_cidr         = "10.8.0.0/28"
  vpc_connector_ip_cidr_range = "10.8.0.16/28"
  repo_id                     = "repo"
  streamlit_image             = "us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit:latest"
  ollama_image                = "ollama/ollama:latest"
  sa_email                    = "${local.service_name}-sa@${local.proj_id}.iam.gserviceaccount.com"
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

provider "google" {
  project = local.proj_id
  region  = local.region
}

resource "google_compute_network" "vpc_network" {
  name                    = local.vpc_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name            = local.vpc_subnetwork_name
  ip_cidr_range   = local.vpc_subnetwork_cidr
  network         = google_compute_network.vpc_network.id
  region          = local.region
  private_ip_google_access = true
}

# resource "google_vpc_access_connector" "connector" {
#   name          = local.vpc_connector_name
#   region        = local.region
#   # network       = google_compute_network.vpc_network.id
#   network       = "default"
#   ip_cidr_range = local.vpc_connector_ip_cidr_range
#   min_throughput = 200
#   max_throughput = 300
# }






# Ollama Service (Private)
resource "google_cloud_run_v2_service" "tf_toms_ollama" {
  name     = "toms-ollama"
  location = local.region
  # ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  # ingress  = "INGRESS_TRAFFIC_ALL"
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  template {
    containers {
      image = "ollama/ollama:latest"
      # command = ["/bin/sh", "-c", "ollama serve & sleep 5 && ollama pull phi3 && wait"]
      command = ["/bin/sh", "-c", "ollama serve & sleep 5 && ollama pull phi3"]
      ports {
        container_port = 11434
      }
      resources {
        limits = {
          cpu    = "2"
          memory = "8Gi"
        }
      }
    }
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    # vpc_access {
    #   connector = google_vpc_access_connector.connector.id
    #   egress    = "ALL_TRAFFIC"
    # }
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress = "ALL_TRAFFIC"
    }
  }
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_v2_service" "tf_toms_frontend_app" {
  name     = "toms-frontend"
  location = local.region
  ingress  = "INGRESS_TRAFFIC_ALL"  
  template {
    containers {
      # image = "us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit-draft:latest"
      image = "us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit:latest"
      ports {
        container_port = 8501
      }
      env {
        name  = "OLLAMA_HOST"
        value = "${google_cloud_run_v2_service.tf_toms_ollama.uri}" # Automatically gets the service URL
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "4Gi"
        }
      }
    }
    # vpc_access {
    #   connector = google_vpc_access_connector.connector.id
    #   egress = "ALL_TRAFFIC"
    # }
    scaling {
      max_instance_count = 1
      min_instance_count = 0
    }
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress = "ALL_TRAFFIC"
    }
  }
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}


# For the Ollama service (being called)
# resource "google_cloud_run_v2_service" "ollama" {
#   name     = "ollama"
#   location = local.region
#   ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY" # Only allow internal traffic  
#   template {
#     containers {
#       image = "your-ollama-image"
#     }    
#     vpc_access {
#       connector = google_vpc_access_connector.connector.id
#     }
#   }
# }


# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "frontend_access" {
  location = google_cloud_run_v2_service.tf_toms_frontend_app.location
  service  = google_cloud_run_v2_service.tf_toms_frontend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "ollama_access" {
  location = google_cloud_run_v2_service.tf_toms_ollama.location
  service  = google_cloud_run_v2_service.tf_toms_ollama.name
  role     = "roles/run.invoker"
  member   = "allUsers"
  # member   = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_vpc_access_connector" "connector" {
  name          = "cloudrun-connector"
  region        = local.region
  ip_cidr_range = "192.168.16.0/28"
  network       = google_compute_network.vpc_network.name
  min_throughput = 200
  max_throughput = 300

  # max_throughput = 300  # Mbps (100-1000), or
  # max_instances = 3   # Alternative (2-10)
}

# resource "google_vpc_access_connector" "connector" {
#   name          = local.vpc_connector_name
#   region        = local.region
#   # network       = google_compute_network.vpc_network.id
#   network       = "default"
#   # ip_cidr_range = local.vpc_connector_ip_cidr_range
#   ip_cidr_range = "10.8.0.0/28"
#   min_throughput = 200
#   max_throughput = 300
# }


# IAM permission for internal communication
# resource "google_cloud_run_service_iam_member" "streamlit_to_ollama" {
#   location = google_cloud_run_v2_service.ollama.location
#   service  = google_cloud_run_v2_service.ollama.name
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:${local.proj_number}-compute@developer.gserviceaccount.com"
# }



# IAM Bindings
# resource "google_cloud_run_v2_service_iam_binding" "streamlit_public" {
#   name     = google_cloud_run_v2_service.streamlit.name
#   location = local.region
#   role     = "roles/run.invoker"
#   members  = ["allUsers"]
# }

# resource "google_cloud_run_v2_service_iam_binding" "ollama_private" {
#   name     = google_cloud_run_v2_service.ollama.name
#   location = local.region
#   role     = "roles/run.invoker"
#   members  = ["allUsers"]
#   # members  = [
#   #   "serviceAccount:${local.proj_id}.svc.id.goog[cloudrun/internal]"
#   # ]
# }


































# --------------------------
# # Grant the service account the Cloud Run Invoker role
# resource "google_project_iam_member" "cloud_run_invoker" {
#   project = var.project_id
#   role    = "roles/run.invoker"
#   member  = "serviceAccount:${local.sa_email}"
#   depends_on = [google_project_service.cloudresourcemanager_api, google_service_account.cloud_run_sa]
# }

# # Grant additional roles to the GitHub Actions service account
# resource "google_project_iam_member" "service_usage_admin" {
#   project = var.project_id
#   role    = "roles/serviceusage.serviceUsageAdmin"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# resource "google_project_iam_member" "service_account_admin" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountAdmin"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# resource "google_project_iam_member" "project_iam_admin" {
#   project = var.project_id
#   role    = "roles/resourcemanager.projectIamAdmin"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# resource "google_project_iam_member" "artifact_registry_admin" {
#   project = var.project_id
#   role    = "roles/artifactregistry.admin"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# resource "google_project_iam_member" "cloud_run_admin" {
#   project = var.project_id
#   role    = "roles/run.admin"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# resource "google_project_iam_member" "service_account_user" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:github-actions-deploy@tom-riddle-diary1.iam.gserviceaccount.com"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# # Create an Artifact Registry repository to store container images
# resource "google_artifact_registry_repository" "repo" {
#   location      = var.region
#   repository_id = local.repo_id
#   format        = "DOCKER"
#   lifecycle {
#     ignore_changes = [repository_id]
#   }
#   depends_on = [google_project_service.artifactregistry_api]
# }

# # Define the Cloud Run service with Streamlit (ingress) and Ollama (sidecar) containers
# resource "google_cloud_run_v2_service" "streamlit_ollama_service" {
#   name     = local.service_name
#   location = var.region
#   deletion_protection = false

#   template {
#     max_instance_request_concurrency = 80
#     timeout                         = "3600s"
#     containers {
#       image = local.streamlit_image
#       name  = "streamlit-container"
#       ports {
#         container_port = 8501
#       }
#       env {
#         name  = "OLLAMA_HOST"
#         value = "http://localhost:11434"
#       }
#       resources {
#         limits = local.resource_limits.streamlit
#       }
#     }
#     containers {
#       image = local.ollama_image
#       name  = "ollama-container"
#       env {
#         name  = "PORT"
#         value = "11434"
#       }
#       command = ["/bin/sh"]
#       args    = ["-c", "ollama serve & sleep 5 && ollama pull phi3 && wait"]
#       resources {
#         limits = local.resource_limits.ollama
#       }
#     }
#     # service_account_name = local.sa_email
#     scaling {
#       min_instance_count = 0
#       max_instance_count = 2
#     }
#     annotations = {
#       "run.googleapis.com/ingress" = "all"
#     }
#   }

#   traffic {
#     type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
#     percent = 100
#   }

#   depends_on = [
#     google_project_service.run_api,
#     google_project_service.artifactregistry_api,
#     google_artifact_registry_repository.repo,
#     google_service_account.cloud_run_sa
#   ]
# }

# # Ensure unauthenticated access
# resource "google_cloud_run_service_iam_member" "public_access" {
#   location = google_cloud_run_v2_service.streamlit_ollama_service.location
#   service  = google_cloud_run_v2_service.streamlit_ollama_service.name
#   role     = "roles/run.invoker"
#   member   = "allUsers"
#   depends_on = [google_project_service.cloudresourcemanager_api]
# }

# # Output the Cloud Run service URL
# output "service_url" {
#   value = google_cloud_run_v2_service.streamlit_ollama_service.uri
# }

# # Define variables
# variable "project_id" {
#   description = "GCP project ID"
#   type        = string
# }

# variable "region" {
#   description = "GCP region"
#   type        = string
#   default     = "us-central1"
# }


