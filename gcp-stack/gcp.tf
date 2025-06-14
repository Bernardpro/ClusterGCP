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

# --- IPs Statique pour services externes ---
resource "google_compute_address" "ingress_static" {
  name   = "ingress-static-ip"
  region = var.region
}

resource "google_compute_address" "argocd_static_ip" {
  name   = "argocd-static-ip"
  region = var.region
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

# --- Instances Ubuntu (nodes Kubernetes) ---
resource "google_compute_instance" "k8s_nodes" {
  count        = 3
  name         = "k8s-node-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2404-lts"
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
    master_ip   = google_compute_instance.k8s_nodes[0].network_interface[0].access_config[0].nat_ip
    worker_ips  = join("\n", slice(google_compute_instance.k8s_nodes[*].network_interface[0].access_config[0].nat_ip, 1, length(google_compute_instance.k8s_nodes[*].network_interface[0].access_config[0].nat_ip)))
  }
}

resource "null_resource" "generate_inventory" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.inventory.rendered}' > inventory.ini"
  }
}

# --- Provisionnement du cluster avec Ansible ---
resource "null_resource" "provision_k8s" {
  depends_on = [
    google_compute_instance.k8s_nodes,
    data.template_file.inventory  
  ]

  provisioner "local-exec" {
    command = <<EOT
      echo "[INFO] Attente que les ports SSH soient disponibles..."

      for ip in $(awk '/ansible_host=/ {for(i=1;i<=NF;i++) if ($i ~ /^ansible_host=/) {split($i,a,"="); print a[2]}}' inventory.ini); do
        echo "[WAIT] Vérification SSH pour $ip ..."
        while ! nc -z -w3 $ip 22; do
          sleep 15
        done
      done

      echo "[INFO] Nettoyage des anciennes clés SSH connues..."
      for ip in $(awk '/ansible_host=/ {for(i=1;i<=NF;i++) if ($i ~ /^ansible_host=/) {split($i,a,"="); print a[2]}}' inventory.ini); do
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ip" || true
      done

      echo "[INFO] Lancement du playbook Ansible..."
      ANSIBLE_HOST_KEY_CHECKING=False \
      uv run ansible-playbook ./ansible/provision-k8s.yml \
        -i inventory.ini \
        --private-key=${var.private_key_path} \
        -u ${var.ssh_user}
    EOT
    interpreter = ["/bin/bash", "-c"]

  }
}
