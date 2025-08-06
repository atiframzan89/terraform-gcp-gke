output "private-subnet-1" {
  value = google_compute_subnetwork.private-subnet["private-subnet-1"].id
}

output "public-subnet-1" {
  value = google_compute_subnetwork.public-subnet["public-subnet-1"].id
}

output "vpc-id" {
  value = google_compute_network.vpc-network.id
}