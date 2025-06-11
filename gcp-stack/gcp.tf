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

# --- VPC : create OR use existing ---
resource "google_compute_network" "main" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "main-vpc"
  auto_create_subnetworks = false
}

data "google_compute_network" "main" {
  count   = var.create_vpc ? 0 : 1
  name    = "main-vpc"
  project = var.project_id
}

locals {
  vpc_id = var.create_vpc ? google_compute_network.main[0].id : data.google_compute_network.main[0].id
}



resource "google_compute_subnetwork" "private" {
  count                    = var.create_subnet ? 1 : 0
  name                     = "private-subnet"
  region                   = var.region
  ip_cidr_range            = "10.0.1.0/24"
  network                  = local.vpc_id
  private_ip_google_access = true
}

data "google_compute_subnetwork" "private" {
  count   = var.create_subnet ? 0 : 1
  name    = "private-subnet"
  region  = var.region
  project = var.project_id
}

locals {
  subnet_id = var.create_subnet ? google_compute_subnetwork.private[0].id : data.google_compute_subnetwork.private[0].id
}


# --- Adresse IP statique pour Ingress NGINX ---
resource "google_compute_address" "ingress_static" {
  name   = "ingress-static-ip"
  region = var.region
}

# --- Cluster GKE ---
resource "google_container_cluster" "gke" {
  name                     = "php-cluster"
  location                 = var.zone
  network                  = local.vpc_id
  subnetwork               = local.subnet_id  
  remove_default_node_pool = true
  initial_node_count       = 1
  ip_allocation_policy {}
}


# --- Node Pool avec autoscaling ---
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
    min_node_count = 1
    max_node_count = 3
  }

  node_count = 1
}

# --- Disque Persistant pour MySQL ---
resource "google_compute_disk" "mysql_data" {
  name  = "mysql-disk"
  size  = 10
  type  = "pd-balanced"
  zone  = var.zone
}
