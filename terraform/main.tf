# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 4.0"
#     }
#   }
# }

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

resource "google_cloud_run_v2_service" "tf_toms_ollama" {
  name     = "toms-ollama"
  location = local.region
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  template {
    containers {
      # image = "ollama/ollama:latest"
      image = "gcr.io/tom-riddle-diary1/ollama"
      # command = ["/bin/sh", "-c", "ollama serve & sleep 5 && ollama pull phi3 && wait"]
      # command = ["/bin/sh", "-c", "ollama serve & sleep 5 && ollama pull phi3"]
      command = ["/bin/sh", "-c", "ollama serve"]
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
}

