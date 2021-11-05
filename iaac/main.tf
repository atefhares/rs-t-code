locals {
  region        = "europe-west2"
  zone          = "europe-west2-b"
}

terraform {
  backend "gcs" {
    bucket  = "${var.project_id}-tfstate-bucket-atefhares"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project     = var.project_id
  region      = local.region
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
}

# -------------------------------------------------------------------------
module "gke_auto" {
  source                     = "./modules/gke_auto_pilot_tf13/main"
  region                     = local.region
  vpc                        = module.gke_network.vpc_id
  subnet                     = module.gke_network.subnet_name
  gke_master_ipv4_cidr_block = "172.23.0.0/28"
  authorized_source_ranges   = ["0.0.0.0/0"] # !!!!!!!!!! FOR TESTING ONLY !!!!!!!!!
  pods_cidr                  = "app-pods-cidr"
  services_cidr              = "app-services-cidr"
}

# module "gke_standard" {
#   source                     = "./modules/gke_standard_tf13/main"
#   region                     = local.region
#   vpc                        = module.gke_network.vpc_id
#   subnet                     = module.gke_network.subnet_name
#   gke_master_ipv4_cidr_block = "172.23.0.0/28"
#   authorized_source_ranges   = ["0.0.0.0/0"]
#   pods_cidr                  = "app-pods-cidr"
#   services_cidr              = "app-services-cidr"
# }
# -------------------------------------------------------------------------


# ---------------------------------------------------------------------------
#  TODO: enable all required apis 
#  Cloud Resource Manager API
#  Google Kubernetes Engine API
#  Cloud Storage API

#  =========================================================================