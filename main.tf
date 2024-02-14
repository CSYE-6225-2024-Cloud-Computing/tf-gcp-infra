############################################################################
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.16.0"
    }
  }
}

#Provider Configuration
provider "google" {
  credentials = file("${path.module}/key.json")
  project     = var.project_id #"csy-6225-sj" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
  region      = var.region #"us-east1" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
}
############################################################################

# VPCs, Subnets, and Routes
locals {
  vpc_names   = [for i in range(var.num_vpcs) : "${var.name}-vpc-${i + 1}"]
  subnet_count = 2  # Number of subnets per VPC
  type        = ["webapp", "db"]  # Example types for subnets
}

resource "google_compute_network" "vpc_network" {
  for_each = { for name in local.vpc_names : name => {
    name                            = name
    auto_create_subnetworks         = false
    routing_mode                    = "REGIONAL"
    delete_default_routes_on_create = true
  }}

  name                            = each.value.name
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  routing_mode                    = each.value.routing_mode
  delete_default_routes_on_create = each.value.delete_default_routes_on_create
}

resource "google_compute_subnetwork" "subnets" {
  for_each = google_compute_network.vpc_network

  name                     = "${each.key}-webapp-subnet"
  ip_cidr_range            = var.ip_cidr_range[0]
  region                   = var.region
  network                  = each.value.self_link
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "subnets_db" {
  for_each = google_compute_network.vpc_network

  name                     = "${each.key}-db-subnet"
  ip_cidr_range            = var.ip_cidr_range[1]
  region                   = var.region
  network                  = each.value.self_link
  private_ip_google_access = true
}

resource "google_compute_route" "webapp_route" {
  for_each = google_compute_network.vpc_network

  name            = "${each.key}-webapp-route"
  network         = each.value.self_link
  dest_range      = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority        = 1000
}


############################################################################

# VPC
# resource "google_compute_network" "vpc_network" {
#   name = "${var.name}-vpc"
#   delete_default_routes_on_create = true
#   auto_create_subnetworks = false
#   routing_mode = "REGIONAL"
# }

# data "google_compute_zones" "available" {
#   region  = var.region
#   project = var.project_id
# }

# locals {
#   type   = ["public-webapp", "private-db"]
#   zones = data.google_compute_zones.available.names
# }


# # SUBNETS
# resource"google_compute_subnetwork""subnets" {
# count= 2
# name="${var.name}-${local.type[count.index]}-subnetwork"
# ip_cidr_range= var.ip_cidr_range[count.index]
# region=var.region
# network=google_compute_network.vpc_network.self_link
# private_ip_google_access =true
# }

# #Route for Webapp Subnet
# resource "google_compute_route" "webapp_route" {
#   name            = "${var.name}-webapp-route"
#   network         = google_compute_network.vpc_network.self_link
#   dest_range      = "0.0.0.0/0"
#   next_hop_gateway = "default-internet-gateway" 
#   priority        = 1000
# }
############################################################################
# NAT ROUTER
# resource "google_compute_router" "nat_router" {
#   name    = "${var.name}-${local.type[1]}-router"
#   region  = var.region
#   network = google_compute_network.vpc_network.self_link
# }

# data "google_compute_zones" "available" {
#   region  = var.region
#   project = var.project_id
# }

# locals {
#   type   = ["public-webapp", "private-db"]
#   zones = data.google_compute_zones.this.names
#}

# resource "google_compute_router_nat" "nat_configuration" {
#   name                               = "${var.name}-${local.type[1]}-router-nat"
#   router                             = google_compute_router.nat_router.name
#   region                             = var.region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
#   subnetwork {
#     name                             = "${var.name}-${local.type[1]}-subnetwork"
#     source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
#   }
# }







# #Creating Main VPC
# resource "google_compute_network" "vpc_network_main" {
#   name                    = var.vpc_network_name# TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
#   auto_create_subnetworks = false
#   routing_mode            = "REGIONAL"
#   #delete_default_routes_on_create = true
# }

# # Creating the Public Subnet: webapp
# resource "google_compute_subnetwork" "webapp_public_subnet" {
#   name          = "webapp"
#   ip_cidr_range = "10.0.1.0/24"
#   network       = google_compute_network.vpc_network_main.id
  
# }

# # Creating the Private Subnet: db
# resource "google_compute_subnetwork" "db_private_subnet" {
#   name          = "db"
#   ip_cidr_range = "10.0.2.0/24"
#   network       = google_compute_network.vpc_network_main.id
 
# }

# # Adding a Route for the webapp Subnet
# resource "google_compute_route" "" {
#   name           = var.router_name # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
#   network        = google_compute_network.vpc_network_main.id
#   dest_range     = "0.0.0.0/0" # All possible ip's
#   next_hop_gateway = "default-internet-gateway" # Read more, i dont know
#   priority       = 1000 # this value indicates the serial order in which the rule will be applied.  
# }
