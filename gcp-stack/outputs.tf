
output "project_id" {
  description = "Le projet GCP utilisé pour ce déploiement"
  value       = var.project_id
}


output "vpc_id" {
  description = "L'ID du VPC créé ou utilisé"
  value       = local.vpc_id
  
}
output "ip_static_app" {
  description = "L'adresse IP statique de l'application déployée"
  value       = var.ingress_static_ip
}

output "ip_static_argocd" {
  description = "L'adresse IP statique d'Argocd"
  value       = var.argocd_static_ip
}

output "ip_static_grafana" {
  description = "L'adresse IP statique de Grafana"
  value       = var.grafana_static_ip
}

output "command" {
  description = "Pour entrer sur la VM master"
  value = "gcloud compute ssh k8s-node-1"
} 