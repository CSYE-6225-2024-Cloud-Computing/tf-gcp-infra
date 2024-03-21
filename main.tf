terraform {
  # required_providers {
  #   google = {
  #     source  = "hashicorp/google"
  #     version = "5.16.0"
  #   }
  # }

required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>5"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "~>4"
    }
  }
}

#Provider Configuration
provider "google" {
  #credentials = file("${path.module}/key.json")
  project = var.project_id #"csy-6225-sj" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
  region  = var.region     #"us-east1" # TODO: this can become as variable name, use the variables.tf file name and enter the key and value in this file
}

# data "template_file" "install" {
#   template = file("${path.module}/startuptesting.sh")
# }

#Define network resources
resource "google_compute_network" "vpcnetwork" {
  count                           = var.vpc_count
  project                         = var.project_id
  name                            = var.vpc_names[count.index]
  auto_create_subnetworks         = false
  mtu                             = 1460
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_global_address" "private_ip_address" {
  count         = var.vpc_count
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpcnetwork[count.index].id
}

resource "google_service_networking_connection" "private_services_connection" {
  count                   = var.vpc_count
  network                 = google_compute_network.vpcnetwork[count.index].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[count.index].name]
  provider                = google-beta
}

resource "google_compute_subnetwork" "webapp" {
  count                    = var.vpc_count
  name                     = var.subnet_webapp_name[count.index]
  ip_cidr_range            = var.subnet_CIDR_webapp[count.index]
  region                   = var.region
  network                  = google_compute_network.vpcnetwork[count.index].id
}

resource "google_compute_subnetwork" "subnet_db" {
  count                    = var.vpc_count
  name                     = var.subnet_db_name[count.index]
  ip_cidr_range            = var.subnet_CIDR_db[count.index]
  region                   = var.region
  network                  = google_compute_network.vpcnetwork[count.index].id
  private_ip_google_access = true
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


#############################################################################

resource "google_sql_database_instance" "cloudsql_instance" {
  depends_on          = [google_service_networking_connection.private_services_connection]
  count               = var.vpc_count
  name                = var.instance_name
  database_version    = var.database_version
  deletion_protection = var.deletion_protection 
  region              = var.region
  settings {
    tier              = var.tier
    availability_type = var.routing_mode
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize = var.disk_autoresize
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.vpcnetwork[count.index].id
    }
  }
}

# Create CloudSQL Database
resource "google_sql_database" "cloudsql_database" {
  count    = var.vpc_count
  name     = var.cloudsql_database_name
  instance = google_sql_database_instance.cloudsql_instance[count.index].name
}

# Generate Random Password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "-_"
}

# Create CloudSQL Database User
resource "google_sql_user" "cloudsql_user" {
  count    = var.vpc_count
  name     = var.cloudsql_user_name
  instance = google_sql_database_instance.cloudsql_instance[count.index].name
  password = random_password.password.result #var.db_password
}

#############################################################################

# Create Service Account for Virtual Machine
resource "google_service_account" "vm_service_account" {
  account_id   = "vm-service-account"
  display_name = "VM Service Account"
}

# Bind IAM Role to the Service Account
resource "google_project_iam_binding" "service_account_iam_binding" {
  project = var.project_id

  role   = "roles/logging.admin"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}

resource "google_project_iam_binding" "metric_writer_iam_binding" {
  project = var.project_id

  role   = "roles/monitoring.metricWriter"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}



#############################################################################

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
    access_config {}
  }


  # Service account for the compute instance
  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
  }

  metadata_startup_script = <<-EOF
#!/bin/bash
exec >> /tmp/logfile.log 2>&1
DB_USERNAME=${google_sql_user.cloudsql_user[count.index].name}
DB_PASSWORD=${random_password.password.result}
DB_HOST=${google_sql_database_instance.cloudsql_instance[count.index].private_ip_address}
DB_NAME=${google_sql_database.cloudsql_database[count.index].name}
POSTGRES_PORT=${var.postgres_port}
APP_USER=${var.app_user}
APP_GROUP=${var.app_group}
ENV_DIR="/home/csye6225/webapp/app/.env"
sudo touch $ENV_DIR
sudo chown $APP_USER:$APP_GROUP $ENV_DIR
sudo chmod 755 $ENV_DIR
sudo echo POSTGRES_DATABASE_URL=postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:$POSTGRES_PORT/$DB_NAME >> $ENV_DIR
sleep 5
sudo systemctl restart webapp.service
  EOF
depends_on = [google_compute_subnetwork.webapp, google_sql_database_instance.cloudsql_instance, google_service_account.vm_service_account]
}


#############################################################################

# Update Cloud DNS zone using Terraform to add or update A records

resource "google_dns_record_set" "csye6225" {
  count        = var.vpc_count
  name         = "sjaiswal.me."
  type        = "A"
  ttl         = 21600
  managed_zone = "csye-zone"
  rrdatas     = [google_compute_instance.my_instance[count.index].network_interface[0].access_config[0].nat_ip]
  depends_on = [google_compute_instance.my_instance]
}

#############################################################################