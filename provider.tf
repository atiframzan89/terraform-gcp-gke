provider "google" {
  project     = var.project-name
  region      = var.region
  credentials = file("./config/terraform-svc-account.json")
}

# Helm Provider
provider "helm" {
  kubernetes = {
    host  = "https://${module.gke.gke-cluster-endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster-ca-cert)
  }
}
