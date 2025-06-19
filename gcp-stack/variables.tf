variable "project_id" {
  description = "value of GOOGLE_CLOUD_PROJECT"
  type = string
}

variable "credentials_file" {
  description = "value of GOOGLE_APPLICATION_CREDENTIALS"
  default     = "credentials/terraform-sa.json"
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "create_vpc" {
  description = "Set to true to create main-vpc, false to use existing"
  type        = bool
  default     = false
}

variable "create_subnet" {
  description = "Set to true to create private-subnet, false to use existing"
  type        = bool
  default     = false
}
variable "github_token" {
  description = "GitHub token for authentication"
  type        = string
}

variable "github_user" {
  description = "GitHub user or organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "app_path" {
  description = "Path to the application Helm chart"
  type        = string
  default     = "helm/sample-app"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application php"
  type        = string
  default     = "sample-app"
}
variable "environnement" {
  description = "Environnement for the application"
  type        = string
  default     = "dev"
}

variable "ssh_user" {
  description = "SSH user for the instances"
  type        = string
  default     = "ubuntu"
}

variable "ssh_key_path" {
  description = "Path to the SSH private key"
  type        = string
  default     = "credentials/ssh-key"
}

variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "credentials/ssh-key.pub"
}

variable "private_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "credentials/ssh-key"
}

variable "argocd_static_ip" {
  description = "Adresse IP publique assignée à ArgoCD"
  type        = string
}

variable "ingress_static_ip" {
  description = "Adresse IP publique assignée à l'Ingress NGINX"
  type        = string
}
variable "grafana_static_ip" {
  description = "Adresse IP publique assignée à Grafana"
  type        = string
}
variable "github_user_login" {
  description = "GitHub user for login"
  type        = string
  default     = "EpitechMscProPromo2025"
}
