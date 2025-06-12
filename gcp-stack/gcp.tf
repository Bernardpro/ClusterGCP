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

resource "google_compute_address" "argocd_static_ip" {
  name   = "argocd-static-ip"
  region = var.region
}

# --- Create 2 VM ubuntu GCP ---
resource "google_compute_instance" "k8s_nodes" {
  count        = 2
  name         = "k8s-node-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.main[0].id
    subnetwork = google_compute_subnetwork.private[0].id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }
}

resource "null_resource" "provision_k8s" {
  depends_on = [google_compute_instance.k8s_nodes]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i inventory.ini provision-k8s.yml --private-key ${var.private_key_path} -u ${var.ssh_user}
    EOT
  }
}


# --- Disque Persistant pour MySQL ---
resource "google_compute_disk" "mysql_data" {
  name  = "mysql-disk"
  size  = 10
  type  = "pd-balanced"
  zone  = var.zone
}

# data "google_client_config" "current" {}

# # --- Installation de cert-manager via Helm ---
# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   namespace  = "cert-manager"
#   version    = "v1.13.2"
#   create_namespace = true

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
# }

# --- Installation d'ArgoCD via Helm ---
# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   namespace  = "argocd"
#   create_namespace = true
#   version    = "5.51.6"

#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "server.service.loadBalancerIP"
#     value = google_compute_address.argocd_static_ip.address
#   }

#   depends_on = [google_compute_address.argocd_static_ip]

# }

# resource "helm_release" "nginx_ingress" {
#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   create_namespace = true
#   timeout = "600"
#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "controller.admissionWebhooks.enabled"
#     value = "false"
#   }
#   set {
#     name  = "controller.service.loadBalancerIP"
#     value = google_compute_address.ingress_static.address
#   }
#   set {
#     name  = "controller.resources.requests.cpu"
#     value = "50m"
#   }

#   set {
#     name  = "controller.resources.requests.memory"
#     value = "64Mi"
#   }
# }


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
