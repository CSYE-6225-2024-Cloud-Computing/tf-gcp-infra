############################################################################
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.16.0"
    }
  }
}

#Provider Configuration
provider "google" {
  #credentials = file("${path.module}/key.json")
  project = var.project_id #"csy-6225-sj" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
  region  = var.region     #"us-east1" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
}
############################################################################

# VPCs, Subnets, and Routes
locals {
  vpc_names    = [for i in range(var.num_vpcs) : "${var.name}-vpc-${i + 1}"]
  subnet_count = 2                # Number of subnets per VPC
  type         = ["webapp", "db"] # Example types for subnets
}

resource "google_compute_network" "vpc_network" {
  for_each = { for name in local.vpc_names : name => {
    name                            = name
    auto_create_subnetworks         = false
    routing_mode                    = "REGIONAL"
    delete_default_routes_on_create = true
  } }

  name                            = each.value.name
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  routing_mode                    = each.value.routing_mode
  delete_default_routes_on_create = each.value.delete_default_routes_on_create
}

resource "google_compute_subnetwork" "subnets" {
  for_each = google_compute_network.vpc_network

  name          = "${each.key}-webapp-subnet"
  ip_cidr_range = var.ip_cidr_range[0]
  region        = var.region
  network       = each.value.self_link
  #private_ip_google_access = true
}

resource "google_compute_subnetwork" "subnets_db" {
  for_each = google_compute_network.vpc_network

  name          = "${each.key}-db-subnet"
  ip_cidr_range = var.ip_cidr_range[1]
  region        = var.region
  #network       = each.value.self_link
  #private_ip_google_access = false
}

resource "google_compute_route" "webapp_route" {
  for_each = google_compute_network.vpc_network

  name             = "${each.key}-webapp-route"
  network          = each.value.self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["webapp"]
}


############################################################################
