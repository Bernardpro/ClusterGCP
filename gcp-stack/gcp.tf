terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}


data "google_compute_network" "vpc" {
  name    = "main-vpc"
  project = var.project_id
}


data "google_compute_subnetwork" "private" {
  name    = "private-subnet"
  region  = var.region
  project = var.project_id
}

# Cluster GKE
resource "google_container_cluster" "gke" {
  name                     = "php-cluster"
  location                 = var.zone
  network                  = data.google_compute_network.vpc.id
  subnetwork               = data.google_compute_subnetwork.private.id
  remove_default_node_pool = true
  initial_node_count       = 1
  ip_allocation_policy {}
}

# Node Pool avec autoscaling
resource "google_container_node_pool" "nodes" {
  cluster  = google_container_cluster.gke.name
  location = var.zone

  node_config {
    machine_type = "e2-small"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 1
  }

  node_count = 1
}

# Persistent Disk pour MySQL
resource "google_compute_disk" "mysql_data" {
  name  = "mysql-disk"
  size  = 10
  type  = "pd-balanced"
  zone  = var.zone
}
