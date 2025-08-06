output "gke-cluster-endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "cluster-ca-cert" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

# output "gke-cluster" {
  
# }