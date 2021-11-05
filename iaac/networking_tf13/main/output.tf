output "vpc_id" {
    value  = google_compute_network.vpc_network.id
}

output "vpc_name" {
    value  = google_compute_network.vpc_network.name
}

output "subnet_name" {
    value  = google_compute_subnetwork.trusted_subnet.name
}

output "subnet_cidr" {
    value  = google_compute_subnetwork.trusted_subnet.ip_cidr_range
}