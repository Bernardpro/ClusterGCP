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

# --- Réseau VPC et Subnet ---
resource "google_compute_network" "main" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "main-vpc-1"
  auto_create_subnetworks = false
}

data "google_compute_network" "main" {
  count   = var.create_vpc ? 0 : 1
  name    = "main-vpc-1"
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


# --- Disque Persitant MySQL protégé ---
resource "google_compute_disk" "mysql_data" {
  name  = "mysql-disk"
  size  = 10
  type  = "pd-balanced"
  zone  = var.zone
}

# --- Règle firewall pour SSH ---
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = local.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]

  description = "Allow SSH from anywhere"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = local.vpc_id

  allow {
    protocol = "all"
  }

  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/8"]  # ou restreint à ton CIDR, ex: "10.0.1.0/24"
  target_tags   = ["ssh-enabled"]

  description = "Allow all internal traffic between nodes"
}


# --- Instances Ubuntu (nodes Kubernetes) ---
resource "google_compute_instance" "k8s_nodes" {
  count        = 3
  name         = "k8s-node-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image =  "ubuntu-minimal-2404-lts-amd64"
      size  = 20
    }
  }

  network_interface {
    network    = local.vpc_id
    subnetwork = local.subnet_id
    access_config {}
  }


  tags = ["ssh-enabled"]

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }
}

# --- Génération de l'inventory.ini ---
data "template_file" "inventory" {
  template = file("${path.module}/template/inventory.tmpl")

  vars = {
    master_public_ip    = google_compute_instance.k8s_nodes[0].network_interface[0].access_config[0].nat_ip
    master_internal_ip  = google_compute_instance.k8s_nodes[0].network_interface[0].network_ip
    worker_block = join("\n", [
      for idx in range(1, 3) : 
      "k8s-node-${idx + 1} ansible_host=${google_compute_instance.k8s_nodes[idx].network_interface[0].access_config[0].nat_ip} k8s_ip=${google_compute_instance.k8s_nodes[idx].network_interface[0].network_ip}"
    ])
  }
}

resource "null_resource" "generate_inventory" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > inventory.ini"
  }
}
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
# EOT
#   }
# }

# --- Provisionnement du cluster avec Ansible ---
resource "null_resource" "provision_k8s" {
  depends_on = [
    google_compute_instance.k8s_nodes,
    data.template_file.inventory  
  ]
  
  provisioner "local-exec" {
    command = <<EOT
      echo "[INFO] Attente que les ports SSH soient disponibles..."
      sleep 30

      echo "[INFO] Nettoyage des anciennes clés SSH connues..."
      for ip in $(awk '/ansible_host=/ {for(i=1;i<=NF;i++) if ($i ~ /^ansible_host=/) {split($i,a,"="); print a[2]}}' inventory.ini); do
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ip" || true
      done

      echo "[INFO] Installation de containerd..."
      ANSIBLE_HOST_KEY_CHECKING=False \
      uv run ansible-playbook ./ansible/install-containerd.yml \
        -i inventory.ini \
        --private-key=${var.private_key_path} \
        -u ${var.ssh_user}
    EOT
    interpreter = ["/bin/bash", "-c"]

  }

  provisioner "local-exec" {
    command = <<EOT
    
      echo "[INFO] Lancement du playbook Ansible change network configuration..."
      ANSIBLE_HOST_KEY_CHECKING=False \
      uv run ansible-playbook ./ansible/update-network.yml \
        -i inventory.ini \
        --private-key=${var.private_key_path} \
        -u ${var.ssh_user}
    EOT
    interpreter = ["/bin/bash", "-c"]

  }
  provisioner "local-exec" {
    command = <<EOT
      echo "[INFO] Lancement du playbook Ansible d'installation de Kubernetes..."
      ANSIBLE_HOST_KEY_CHECKING=False \
      uv run ansible-playbook ./ansible/install-kubernetes.yml \
        -i inventory.ini \
        --private-key=${var.private_key_path} \
        -u ${var.ssh_user}
    EOT
    interpreter = ["/bin/bash", "-c"]

  }

  provisioner "local-exec" {
    command = <<EOT
      echo "[INFO] Initialisation du cluster Kubernetes..."
      ANSIBLE_HOST_KEY_CHECKING=False \
      uv run ansible-playbook ./ansible/init-cluster.yml \
        -i inventory.ini \
        --private-key=${var.private_key_path} \
        -u ${var.ssh_user}
    EOT
    interpreter = ["/bin/bash", "-c"]

  }

}
