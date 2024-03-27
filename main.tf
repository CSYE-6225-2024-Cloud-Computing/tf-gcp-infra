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


############################################# GOOGLE SQL DATABASE INSTANCE #############################################

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

############################################# VM SERVICE ACCOUNT #############################################

# Create Service Account for Virtual Machine
resource "google_service_account" "vm_service_account" {
  account_id   = "sj-service-account"
  display_name = "SJ Service Account"
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

# Grant Cloud Run Invoker role to the Service Account
resource "google_project_iam_binding" "cloud_run_invoker_binding" {
  project = var.project_id

  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}

# Grant Viewer role to the Service Account
resource "google_project_iam_binding" "viewer_role_binding" {
  project = var.project_id

  role    = "roles/viewer"
  members = ["serviceAccount:${google_service_account.vm_service_account.email}"]
}



############################################## GOOGLE COMPUTE INSTANCE #############################################

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
    scopes = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/pubsub"]

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
sudo echo GCP_PROJECT_ID=${var.project_id} >> $ENV_DIR
sleep 5
sudo systemctl restart webapp.service
  EOF
depends_on = [google_compute_subnetwork.webapp, google_sql_database_instance.cloudsql_instance, google_service_account.vm_service_account]

}


############################################## GOOGLE DNS RECORD SET #############################################

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

############################################## PUB/SUB - TOPIC #############################################

resource "google_pubsub_topic" "verify_email" {
  name = var.pubsub_topic

  labels = {
    foo = "bar"
  }
  message_retention_duration = var.retention_time
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = var.project_id
  topic = google_pubsub_topic.verify_email.name
  role  = var.pubsub_publisher
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}",
  ]
}

############################################## BUCKET VARIABLES #############################################

resource "random_id" "bucket_suffix" {
  byte_length = 8
}
resource "google_storage_bucket" "bucket" {
  name     = "csye-webapp-${random_id.bucket_suffix.hex}"
  location = var.bucket_location
}

# resource "google_storage_bucket_object" "object" {
#   name   = "function-source.zip"
#   bucket = google_storage_bucket.bucket.name
#   source = "function-source.zip"  # Add path to the zipped function source code
# }


########################################### VPC CONNECT #############################################

resource "google_vpc_access_connector" "connector" {
  count        = var.vpc_count
  name          = "connector"
  ip_cidr_range = "10.8.0.0/28"
  network     = google_compute_network.vpcnetwork[count.index].self_link
}


########################################## CLOUD FUNCTION VARIABLES ###################################

resource "google_cloudfunctions2_function" "function" {
  count = var.vpc_count
  name = var.cloud_function_name
  location = var.region
  description = "a new function"

  build_config {
    runtime = var.cloud_runtime
    entry_point = var.cloud_entry_point # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = var.cloud_function_object
      }
    }
    environment_variables = {
    DB_USERNAME=google_sql_user.cloudsql_user[count.index].name,
    DB_PASSWORD=google_sql_user.cloudsql_user[count.index].password,
    DB_HOST=google_sql_database_instance.cloudsql_instance[count.index].private_ip_address,
    DB_NAME=google_sql_database.cloudsql_database[count.index].name,
    MAILGUN_API_KEY=var.MAILGUN_API_KEY,
    DB_PORT = var.postgres_port
    }
  }

  service_config {
    max_instance_count  = 3
    min_instance_count = 1
    available_memory    = "256M"
    timeout_seconds     = 60
    environment_variables = {
      SERVICE_CONFIG_TEST = "config_test"
    }
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    vpc_connector = "projects/dev-gcp-project-414615/locations/us-west1/connectors/connector" 
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.vm_service_account.email
  }

  event_trigger {
    trigger_region = var.region
    event_type = var.cloud_event_type
    pubsub_topic = google_pubsub_topic.verify_email.id
    retry_policy = var.cloud_retry_policy
  }
  depends_on   = [google_vpc_access_connector.connector]
}
