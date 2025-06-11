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

data "google_container_cluster" "gke" {
  name     = google_container_cluster.gke.name
  location = var.zone
}

data "google_client_config" "current" {}


provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.gke.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

# --- Installation de cert-manager via Helm ---
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.13.2"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# --- Installation d'ArgoCD via Helm ---
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  version    = "5.51.6"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

# Apply the stack once and uncomment the next block to deploy the ArgoCD application
# --- Déploiement de l'application via ArgoCD ---

# Uncomment the following block to deploy the application via ArgoCD

# resource "null_resource" "argocd_app" {
#   provisioner "local-exec" {
#     command = <<EOT
#       echo '${templatefile("${path.module}/argocd_app.yaml.tmpl", {
#         github_user    = var.github_user,
#         github_repo    = var.github_repo,
#         app_path       = var.app_path,
#         github_token   = var.github_token,
#         environnement  = var.environnement,
#         app_namespace  = var.app_namespace
#       })}' > /tmp/argocd_app.yaml

#       kubectl apply -f /tmp/argocd_app.yaml
#     EOT
#   }

#   depends_on = [helm_release.argocd]
# }
