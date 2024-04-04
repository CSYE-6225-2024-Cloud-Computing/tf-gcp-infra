
# ############################################# VPC NETWORK CONNECTION #############################################

resource "google_compute_network" "vpcnetwork" {
  count                           = var.vpc_count
  project                         = var.project_id
  name                            = var.vpc_names[count.index]
  auto_create_subnetworks         = var.auto_create_subnetworks
  mtu                             = 1460
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

# ############################################# ADDING FIREWALL #############################################

resource "google_compute_firewall" "allow_web_traffic" {
  count   = var.vpc_count
  name    = "allow-web-traffic-${count.index}"
  network = google_compute_network.vpcnetwork[count.index].self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = var.allow_protocol
    ports    = var.allowed_ports
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = var.allow_priority
}

resource "google_compute_firewall" "deny_all_traffic" {
  count       = var.vpc_count
  name        = "deny-all-traffic-${count.index}"
  network     = google_compute_network.vpcnetwork[count.index].self_link
  target_tags = ["webapp"]

  deny {
    protocol = var.deny_protocol
  }

  source_ranges = ["0.0.0.0/0"]

  priority = var.deny_priority
}

# ############################################# WEBAPP SUBNET #####################################################

resource "google_compute_subnetwork" "webapp" {
  count         = var.vpc_count
  name          = var.subnet_webapp_name[count.index]
  ip_cidr_range = var.subnet_CIDR_webapp[count.index]
  region        = var.region
  network       = google_compute_network.vpcnetwork[count.index].id
}
# ############################################# GLOBAL ADDRESS AND NETWORKING  CONNECTION ########################

resource "google_compute_global_address" "private_ip_address" {
  count         = var.vpc_count
  name          = "private-ip-address"
  purpose       = var.private_ip_address_purpose
  address_type  = var.private_ip_address_type
  prefix_length = var.private_ip_address_prefix_length
  network       = google_compute_network.vpcnetwork[count.index].id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.vpc_count
  network                 = google_compute_network.vpcnetwork[count.index].id
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[count.index].name]
}

# ############################################# WEBAPP ROUTE ############################################

resource "google_compute_route" "webapp_route" {
  count            = var.vpc_count
  name             = "${var.webapp_route}-${count.index + 1}"
  network          = google_compute_network.vpcnetwork[count.index].self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "global/gateways/default-internet-gateway"
  priority         = 1000
}

# ############################################# GOOGLE SQL DATABASE INSTANCE #############################################

resource "google_sql_database_instance" "cloudsql_instance" {
  depends_on          = [google_service_networking_connection.private_vpc_connection]
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
    disk_autoresize   = var.disk_autoresize
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


# #############################################  SERVICE ACCOUNT  #############################################

resource "google_service_account" "service_account" {
  account_id   = "jais-service-account"
  display_name = "jaiswal-service-account"
}


resource "google_project_iam_binding" "metricWriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "Logging_Admin" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

# #############################################  COMPUTE REGION INSTANCE TEMPLATE #############################################

resource "google_compute_region_instance_template" "vm_template" {
  count                = var.vpc_count
  name                 = "webapp-template"
  description          = "This template is used to create webapp server instances."
  instance_description = "description assigned to instances"
  machine_type         = var.machine_type
  can_ip_forward       = false
  tags                 = ["web-servers"]
  # scheduling {
  #   automatic_restart   = true
  #   on_host_maintenance = "MIGRATE"
  # }
  disk {
    source_image = var.packer_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.initialize_params_size # Boot disk size in GB
    disk_type    = var.initialize_params_type
  }
  network_interface {
    subnetwork = google_compute_subnetwork.webapp[count.index].id
    network    = google_compute_network.vpcnetwork[count.index].id
    access_config {
      network_tier = "STANDARD"
    }
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

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_sql_database_instance.cloudsql_instance, google_service_account.service_account]

}


################################## HEALTH CHECK ##################################

resource "google_compute_health_check" "http-health-check" {
  name        = "http-health-check"
  description = "Health check via http"

  timeout_sec         = 5
  check_interval_sec  = 15
  healthy_threshold   = 4
  unhealthy_threshold = 4

  http_health_check {
    port               = 8000
    port_specification = "USE_FIXED_PORT"
    # host               = "1.2.3.4"
    request_path = "/healthz/"
    #response     = ""
  }
  log_config {
    enable = true
  }

}

################################## HEALTH CHECK FIREWALL ##################################
resource "google_compute_firewall" "health-check" {
  count = var.vpc_count
  name  = "fw-allow-health-check"
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000"] # Replace with your health check ports
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpcnetwork[count.index].id
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-servers"]
}
######################################## REGION AUTOSCALAR ########################################

resource "google_compute_region_autoscaler" "autoscaler" {
  count  = var.vpc_count
  name   = "my-region-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.appserver[count.index].id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.05
    }
  }
}

######################################## COMPUTE INSTANCE GROUP MANAGER ########################################

resource "google_compute_region_instance_group_manager" "appserver" {
  name                      = "appserver-igm"
  count                     = var.vpc_count
  base_instance_name        = "webapp"
  region                    = var.region
  distribution_policy_zones = ["us-central1-a", "us-central1-f"]
  # distribution_policy_target_shape = "BALANCED"
  version {
    instance_template = google_compute_region_instance_template.vm_template[count.index].self_link
  }

  named_port {
    name = "http"
    port = 8000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http-health-check.id
    initial_delay_sec = 300
  }
}

# #############################################  SSL CERTIFICATE #############################################

resource "google_compute_managed_ssl_certificate" "lb_default" {
  name = "myservice-ssl-cert"
  managed {
    domains = ["sjaiswal.me"]
  }
}

######################################## LOAD BALANCER ########################################

# backend subnet
resource "google_compute_subnetwork" "default" {
  count         = var.vpc_count
  name          = "backend-subnet"
  ip_cidr_range = "10.1.2.0/24"
  region        = var.region
  # purpose       = "PRIVATE"
  network = google_compute_network.vpcnetwork[count.index].id
  # stack_type    = "IPV4_ONLY"
  private_ip_google_access = true
}
# reserved IP address
resource "google_compute_global_address" "default" {
  # provider = google-beta
  name = "static-address"
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  count = var.vpc_count
  name  = "l7-xlb-forwarding-rule"
  # provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.lb_default[count.index].id
  ip_address            = google_compute_global_address.default.id
}


# http proxy
resource "google_compute_target_https_proxy" "lb_default" {
  count = var.vpc_count
  # provider = google-beta
  name    = "myservice-https-proxy"
  url_map = google_compute_url_map.default[count.index].id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

# url map
resource "google_compute_url_map" "default" {
  count           = var.vpc_count
  name            = "url-map-regional"
  default_service = google_compute_backend_service.default[count.index].id
}

# backend service with custom request and response headers
resource "google_compute_backend_service" "default" {
  count                 = var.vpc_count
  name                  = "backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"
  health_checks         = [google_compute_health_check.http-health-check.id]
  protocol              = "HTTP"
  session_affinity      = "NONE"
  timeout_sec           = 30
  backend {
    group           = google_compute_region_instance_group_manager.appserver[count.index].instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  log_config {
    enable = true
  }
}
# # ############################################## GOOGLE DNS RECORD SET #############################################

# Update Cloud DNS zone using Terraform to add or update A records

resource "google_dns_record_set" "csye6225" {
  count        = var.vpc_count
  name         = "sjaiswal.me."
  type         = "A"
  ttl          = 21600
  managed_zone = "csye-zone"
  rrdatas      = [google_compute_global_address.default.address]
  depends_on   = [google_compute_backend_service.default]
}

# ############################################## PUB/SUB - TOPIC #############################################

resource "google_pubsub_topic" "verify_email" {
  name = var.pubsub_topic

  labels = {
    foo = "bar"
  }
  message_retention_duration = var.retention_time
}

resource "google_pubsub_topic_iam_binding" "binding" {
  project = var.project_id
  topic   = google_pubsub_topic.verify_email.name
  role    = var.pubsub_publisher
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
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
  count         = var.vpc_count
  name          = "connector"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpcnetwork[count.index].self_link
}


########################################## CLOUD FUNCTION VARIABLES ###################################

resource "google_cloudfunctions2_function" "function" {
  count       = var.vpc_count
  name        = var.cloud_function_name
  location    = var.region
  description = "a new function"

  build_config {
    runtime     = var.cloud_runtime
    entry_point = var.cloud_entry_point # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = var.cloud_function_object
      }
    }
    environment_variables = {
      SERVICE_BUILD_TEST = "build_test"
      # DB_USERNAME=google_sql_user.cloudsql_user[count.index].name,
      # DB_PASSWORD=google_sql_user.cloudsql_user[count.index].password,
      # DB_HOST=google_sql_database_instance.cloudsql_instance[count.index].private_ip_address,
      # DB_NAME=google_sql_database.cloudsql_database[count.index].name,
      # MAILGUN_API_KEY=var.MAILGUN_API_KEY,
      # DB_PORT = var.postgres_port
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      DB_USERNAME     = google_sql_user.cloudsql_user[count.index].name,
      DB_PASSWORD     = google_sql_user.cloudsql_user[count.index].password,
      DB_HOST         = google_sql_database_instance.cloudsql_instance[count.index].private_ip_address,
      DB_NAME         = google_sql_database.cloudsql_database[count.index].name,
      MAILGUN_API_KEY = var.MAILGUN_API_KEY,
      DB_PORT         = var.postgres_port
    }
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    vpc_connector                  = "projects/dev-gcp-project-414615/locations/${var.region}/connectors/connector"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.service_account.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = var.cloud_event_type
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = var.cloud_retry_policy
  }
  depends_on = [google_vpc_access_connector.connector]
}
