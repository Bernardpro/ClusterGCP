output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "mysql_disk_name" {
  value = google_compute_disk.mysql_data.name
}
