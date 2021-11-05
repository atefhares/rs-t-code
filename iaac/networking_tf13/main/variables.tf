variable "region" {
    type     = string
}

variable "vpc_name" {
    type     = string
}

variable "subnet_name" {
    type     = string
}

variable "subnet_cidr" {
    type     = string
}

variable "secondary_ip_ranges" {
    type     = map
    default = {}
}