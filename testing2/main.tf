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



resource "google_compute_network" "vpcnetwork" {
  count                           = var.vpc_count
  project                         = var.project_id
  name                            = var.vpc_names[count.index]
  auto_create_subnetworks         = false
  mtu                             = 1460
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}
 
resource "google_compute_subnetwork" "webapp" {
  count         = var.vpc_count
  name          = var.subnet_webapp_name[count.index]
  ip_cidr_range = var.subnet_CIDR_webapp[count.index]
  region        = var.region
  network       = google_compute_network.vpcnetwork[count.index].id
}
 
resource "google_compute_subnetwork" "subnet_db" {
  count         = var.vpc_count
  name          = var.subnet_db_name[count.index]
  ip_cidr_range = var.subnet_CIDR_db[count.index]
  region        = var.region
  network       = google_compute_network.vpcnetwork[count.index].id
}
 
resource "google_compute_route" "webapp_route" {
  count            = var.vpc_count
  name             = "${var.webapp_route}-${count.index + 1}"
  network          = google_compute_network.vpcnetwork[count.index].self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "global/gateways/default-internet-gateway"
  priority         = 1000
  tags             = ["webapp"]
}
 
# Define firewall rule
resource "google_compute_firewall" "allow_web_traffic" {
  count       = var.vpc_count
  name        = "allow-web-traffic"
  network     = google_compute_network.vpcnetwork[count.index].self_link
  target_tags = ["webapp"]
  allow {
    protocol = "icmp"
  }
 
  allow {
    protocol = "tcp"
    ports    = ["22", "80", tostring(var.server_port)]
  }
  source_ranges = ["0.0.0.0/0"]
}

################################################################################################
# Create CloudSQL Instance
resource "google_sql_database_instance" "cloudsql_instance" {
  name               = "csye6225-cloudsql-instance"
  database_version   = "POSTGRES_15"
  deletion_protection = false
  region             = var.region

  settings {
    tier             = "db-custom-1-3840"
    availability_type = "regional"
    disk_type        = "pd-ssd"
    disk_size        = 100
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpcnetwork[count.index].name
    }
  }
}

################################################################################################

 
# Define Compute Engine instance
resource "google_compute_instance" "my_instance" {
  count        = var.vpc_count
  name         = var.my_instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["webapp"]
  boot_disk {
    initialize_params {
      image = var.packer_image           # Custom image name
      size  = var.initialize_params_size # Boot disk size in GB
      type  = var.initialize_params_type # Boot disk type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.webapp[count.index].name # Assuming you have only one VPC network
    access_config {
      # Optional. Leave it blank for ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
#!/bin/bash
exec >> /var/log/logfile.log 2>&1
# Set your GCP-specific configurations
PROJECT_ID=${var.project_id}
REGION=${var.region}

# Set your app-specific values
POSTGRES_DB=${var.postgres_db}
POSTGRES_USER=${var.postgres_user}
POSTGRES_PASSWORD=${var.postgres_password}
POSTGRES_URI=${var.postgres_uri}
POSTGRES_PORT=${var.postgres_port}
SERVER_PORT=${var.server_port}
APP_USER=${var.app_user}
APP_PASSWORD=${var.app_password}
APP_GROUP=${var.app_group}
APP_DIR=${var.app_dir}
ENV_DIR="/home/csye6225/webapp/.env"

# Change ENV owner and permissions
sudo touch $ENV_DIR
sudo chown $APP_USER:$APP_GROUP $ENV_DIR
sudo chmod 660 $ENV_DIR

# Add ENV variables
sudo echo POSTGRES_DATABASE_URL=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_URI:$POSTGRES_PORT/$POSTGRES_DB >> $ENV_DIR

# Restart systemd service
sudo systemctl restart webapp.service
  EOF
}