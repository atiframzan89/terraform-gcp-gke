# Service Account

resource "google_service_account" "gke-service-account" {
  account_id   = "${var.customer}-svc-account"
  display_name = "${var.customer}-svc-account"
}

# Ref https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  name                  = "${var.customer}-gke-cluster"
#   location = "${var.region}"
  network               = var.vpc-id
  subnetwork            = var.private-subnet-1
  location              = var.zonal-location[0]
  deletion_protection   = false
  workload_identity_config {
    workload_pool = "${var.project-id}.svc.id.goog"
  }

  # GCE Ingress Controller
  addons_config {
    http_load_balancing {
      disabled = false  # This enables the GCE Ingress Controller
    }
  }
  # private_cluster_config is the prerequiste for control_plane_endpoints_config
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # This allows external access to control plane via DNS
    # master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#dns_endpoint_config-1
  # If you are adding control plane changes for existing GKE it wont apply you need to recreate the cluster again while making some changes to cluster name etc
    control_plane_endpoints_config {
      dns_endpoint_config {
        allow_external_traffic = true # You need to mention this otherwise DNS Endpoint in GKE Console will not enable
      }
    }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${var.customer}-node-pool-${var.environment}"
  location   = var.zonal-location[0]
  cluster    = google_container_cluster.primary.name
  node_count = 1

  management {
    auto_upgrade    = true
    auto_repair     = true
  }
  
  upgrade_settings {
    strategy            = "SURGE"
    max_surge           = "1"
    max_unavailable     = "0"
  }



  node_config {
    # Security (High): https://aquasecurity.github.io/tfsec/v1.28.1/checks/google/gke/metadata-endpoints-disabled/
    metadata = {
      disable-legacy-endpoints = true
    }
    # Security (High): https://aquasecurity.github.io/tfsec/v1.28.1/checks/google/gke/node-metadata-security/
    workload_metadata_config {
      mode = "GKE_METADATA"
      # node_metadata = "SECURE" # This is available on provider version before 4
    }
    # Security (High): https://aquasecurity.github.io/tfsec/v1.28.1/checks/google/gke/enforce-pod-security-policy/
    # pod_security_policy_config {
    #      enabled = "true"
    # }
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = "30"
    disk_type    = "pd-standard" 
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke-service-account.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Deploying Helm Application

resource "helm_release" "wordpress-chart" {
  name       = "wordpress"
  namespace  = "default"

  chart      = "${path.module}/../../wordpress"
  # version    = "0.1.0"  # Optional: must match Chart.yaml if set

  values = [
    file("${path.module}/../../wordpress/values.yaml")
  ]

  dependency_update = true  # If your chart has dependencies
  wait              = true  # Wait until resources are ready
  timeout           = 600
}

# Promethus Helms
resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.6.0" # latest as of May 2025

  values = [
    file("${path.module}/config/prometheus.yml")
  ]
  depends_on = [ helm_release.grafana ]
}

# Grafana Helm
resource "helm_release" "grafana" {
  name       = "grafana"
  create_namespace = true
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.3.9"
  values = [
    file("${path.module}/config/grafana.yml")
  ]
  # set {
  #   name  = "adminPassword"
  #   value = "supersecret"
  # }

  # set {
  #   name  = "service.type"
  #   value = "LoadBalancer"
  # }
}