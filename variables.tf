variable "project_id" {
  type           = string
  description  = "Project ID"
  default        = "csy-6225-sj"
}

variable "region" {
  type           = string
  description  = "Region for this infrastructure"
  default        = "us-central1"
}

variable "name" {
  type           = string
  description  = "Name for this infrastructure"
  default       = "cloud-2024"
}

variable"ip_cidr_range" {
type=list(string)
description="List of The range of internal addresses that are owned by this subnetwork."
default=["10.10.10.0/24", "10.10.20.0/24"]
}

variable "num_vpcs" {
  type        = number
  description = "Number of VPCs to create"
  default = 2
}
