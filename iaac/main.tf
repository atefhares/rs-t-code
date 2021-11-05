terraform {
  backend "gcs" {
    bucket  = "tfstate-bucket-atefhares-dgtsaw1v"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# -------------------------------------------------------------------------
module "gke_network" {
  source              = "./modules/networking_tf13/main"
  region              = var.region
  vpc_name            = "gke-network"
  subnet_name         = "safe-subnet"
  subnet_cidr         = "20.0.0.0/16"
  secondary_ip_ranges = {
    "safe-subnet": [
      { name: "app-services-cidr", cidr: "20.1.20.0/24" }, 
      { name: "app-pods-cidr", cidr: "20.2.20.0/24" },
    ],
  }

  depends_on          = [google_project_service.compute-api]
}

# -------------------------------------------------------------------------
module "gke_auto" {
  source                     = "./modules/gke_auto_pilot_tf13/main"
  region                     = var.region
  vpc                        = module.gke_network.vpc_id
  subnet                     = module.gke_network.subnet_name
  gke_master_ipv4_cidr_block = "172.23.0.0/28"
  authorized_source_ranges   = [var.gke_authorized_source_ranges] 
  pods_cidr                  = "app-pods-cidr"
  services_cidr              = "app-services-cidr"

  depends_on          = [module.gke_network, google_project_service.container-api]
}

# ---------------------------------------------------------------------------
#  enable all required apis 

resource "google_project_service" "compute-api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "container-api" {
  project = var.project_id
  service = "container.googleapis.com"
}


# ---------------------------------------------------------------------------

# to be used by nginx chart to protect the access. [missing permissions]

resource "google_compute_security_policy" "policy" {
  name = "only-allow-authrozised-users"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["${var.gke_authorized_source_ranges}"]
      }
    }
    description = "allow only access from this CIDR"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny access from internet"
  }
}


# ---------------------------------------------------------------------------
# Creating a global external static IP to use with nginx

resource "google_compute_global_address" "nginx-address" {
  name = "global-nginx-ip"
}

# ---------------------------------------------------------------------------

# Deploying the nginx chart with helm provider

resource "null_resource" "get_cluster_cred" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${module.gke_auto.cluster_name} --region ${var.region} --project ${var.project_id}"
  }

  depends_on = [module.gke_auto]
}

resource "helm_release" "nginx-helm-release" {
  name       = "nginx-chart"
  chart      = "./k8s/helm_charts/nginx"
  
  set {
    name  = "cloud_armor_policy_name"
    value = "${google_compute_security_policy.policy.name}"
  }

  set {
    name  = "external_ip_address"
    value = "${google_compute_global_address.nginx-address.name}"
  }

  depends_on = [null_resource.get_cluster_cred, google_compute_security_policy.policy, google_compute_global_address.nginx-address]
}

# ---------------------------------------------------------------------------
# Monitor the nginx with an up-time check [missing permissions]

resource "google_monitoring_uptime_check_config" "nginx_down_uptime_check" {
  display_name = "nginx_down_uptime_check"

  http_check {
    mask_headers   = "false"
    path           = "/"
    port           = "80"
    request_method = "GET"
    use_ssl        = "false"
    validate_ssl   = "false"
  }

  monitored_resource {
    labels = {
      host       = "${google_compute_global_address.nginx-address.name}"
      project_id = var.project_id
    }

    type = "uptime_url"
  }

  period  = "60s"
  project = var.project_id
  timeout = "10s"
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Test Notification Channel"
  type         = "email"
  labels = {
    email_address = "${var.notifications_email}"
  }
}

resource "google_monitoring_alert_policy" "nginx_down_uptime_check_failure_alert" {
  combiner = "OR"

  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
        per_series_aligner   = "ALIGN_NEXT_OLDER"
      }

      comparison      = "COMPARISON_GT"
      duration        = "300s"
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"${google_monitoring_uptime_check_config.nginx_down_uptime_check.display_name}\""
      threshold_value = "1"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "Failure of uptime check_id ${google_monitoring_uptime_check_config.nginx_down_uptime_check.display_name}"
  }

  display_name          = "${google_monitoring_uptime_check_config.nginx_down_uptime_check.display_name} failure"
  enabled               = "true"
  notification_channels = [google_monitoring_notification_channel.email.id] # this will send an email
  project               = var.project_id
}