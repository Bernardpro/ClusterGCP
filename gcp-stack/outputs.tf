output "web_public_ip" {
  value = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "sql_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "vm_ssh" {
  value = "ssh google_compute_engine ${google_compute_instance.web.name} --project=${var.project_id}"
}

output "web_url" {
  value = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}
