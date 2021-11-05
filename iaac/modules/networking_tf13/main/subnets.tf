resource "google_compute_subnetwork" "trusted_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
  dynamic "secondary_ip_range" {
    for_each      = lookup(var.secondary_ip_ranges, var.subnet_name)
    content {
        range_name    = secondary_ip_range.value.name
        ip_cidr_range = secondary_ip_range.value.cidr
    }
  }
}