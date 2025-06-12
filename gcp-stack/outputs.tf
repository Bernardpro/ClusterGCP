output "mysql_disk_name" {
  value = google_compute_disk.mysql_data.name
}

output "project_id" {
  description = "Le projet GCP utilisé pour ce déploiement"
  value       = var.project_id
}

output "ingress_static_ip" {
  description = "Adresse IP publique assignée à l'Ingress NGINX"
  value       = google_compute_address.ingress_static.address
}

output "argocd_static_ip" {
  description = "Adresse IP publique assignée à ArgoCD (si déclarée)"
  value       = try(google_compute_address.argocd_static_ip.address, "non défini")
}
