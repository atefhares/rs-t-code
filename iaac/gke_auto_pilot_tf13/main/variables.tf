variable "region" {
    type     = string
}

variable "vpc" {
    type     = string
}

variable "subnet" {
    type     = string
}

variable "gke_master_ipv4_cidr_block" {
    type     = string
}

variable "authorized_source_ranges" {
    type     = list(string)
    default  = []
}

variable "pods_cidr" {
    type     = string
}
variable "services_cidr" {
    type     = string
}