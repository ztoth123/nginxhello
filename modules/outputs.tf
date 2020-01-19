output "cluster_client_certificate" {
  value = google_container_cluster.primary.master_auth[0].client_certificate
}

output "cluster_client_key" {
  value = google_container_cluster.primary.master_auth[0].client_key
}

output "cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "endpoint" {
  value = google_container_cluster.primary.endpoint
}