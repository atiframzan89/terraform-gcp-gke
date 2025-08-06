data "google_compute_zones" "available" {}

# For helm provider
data "google_client_config" "default" {}

# data "google_container_cluster" "cluster-data" {
#   name     = "${var.customer}-gke-${var.environment}"
#   location = data.google_compute_zones.available.names[0] # e.g., us-central1-a or us-central1
# #   depends_on = [ module.gke ]
# }