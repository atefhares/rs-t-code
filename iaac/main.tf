locals {
  region        = "europe-west2"
  zone          = "europe-west2-b"
}

terraform {
  backend "gcs" {
    bucket  = "tfstate-bucket-atefhares-dgtsaw1v"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project     = var.project_id
  region      = local.region
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# -------------------------------------------------------------------------
module "gke_network" {
  source              = "./modules/networking_tf13/main"
  region              = local.region
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
  region                     = local.region
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


#  =========================================================================
# Deploying the nginx chart with helm provider
resource "helm_release" "nginx-helm-release" {
  name       = "nginx-chart"
  chart      = "./k8s/helm_charts/nginx"
  
  
  depends_on = [module.gke_auto]
}