########################################## Create Key Ring to store Customer-Managed Encryption Keys (CMEK) ###################################
resource "google_kms_key_ring" "key_ring" {
  name     = "my-key-ring-v7"
  location = var.region  # Specify the region for the Key Ring
}

########################################## Customer-managed encryption keys (CMEK) for Virtual Machines ###################################
resource "google_kms_crypto_key" "vm_crypt_key" {
  key_ring  = google_kms_key_ring.key_ring.id
  name      = "vm-crypt-key"
  rotation_period = "2592000s"  # Set rotation period to 30 days
}

########################################## Customer-managed encryption keys (CMEK) for CloudSQL Instances ###################################
resource "google_kms_crypto_key" "cloudsql_crypt_key" {
  key_ring  = google_kms_key_ring.key_ring.id
  name      = "cloudsql_crypt_key"
  rotation_period = "2592000s"  # Set rotation period to 30 days
}


########################################## # Create Customer-Managed Encryption Key (CMEK) for Cloud Storage Buckets ###################################
resource "google_kms_crypto_key" "storage_crypt_key" {
  name            = "storage-crypt-key"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s"
}

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
  target_tags = ["webapp", "web-servers"]

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
  private_ip_google_access = true
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
  dest_range       = var.webapp_route_dest_range
  next_hop_gateway = var.webapp_route_next_hop_gateway
  priority         = 1000
}

# #############################################  SERVICE ACCOUNT  #############################################

resource "google_service_account" "service_account" {
  account_id   = "jais-service-account"
  display_name = "jaiswal-service-account"
}


resource "google_project_iam_binding" "metricWriter" {
  project = var.project_id
  role    = var.metric_writer_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_project_iam_binding" "Logging_Admin" {
  project = var.project_id
  role    = var.logging_admin_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}


# ############################################# SERVICE ACCOUNTS PREDEFINED #############################################

#CLOUD SQL INSTANCE
resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project = var.project_id
  service = "sqladmin.googleapis.com"
}
resource "google_kms_crypto_key_iam_binding" "crypto_key-sql" {
  crypto_key_id = google_kms_crypto_key.cloudsql_crypt_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

#BUCKET STORAGE 
data "google_storage_project_service_account" "gcs_account" {
}

resource "google_kms_crypto_key_iam_binding" "storage-binding" {
  crypto_key_id = google_kms_crypto_key.storage_crypt_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}



#VM-INSTANCES
resource "google_kms_crypto_key_iam_binding" "vm-instance-binding" {
  crypto_key_id = google_kms_crypto_key.vm_crypt_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members        = [
    "serviceAccount:service-680381513946@compute-system.iam.gserviceaccount.com"
  ]
}

# ############################################# GOOGLE SQL DATABASE INSTANCE #############################################

resource "google_sql_database_instance" "cloudsql_instance" {
  depends_on          = [google_service_networking_connection.private_vpc_connection, google_kms_crypto_key_iam_binding.crypto_key-sql]
  count               = var.vpc_count
  name                = var.database_instance_name
  database_version    = var.database_version
  deletion_protection = var.database_deletion_protection
  region              = var.region
  settings {
    tier              = var.database_tier
    availability_type = var.routing_mode
    disk_type         = var.database_disk_type
    disk_size         = var.databse_disk_size
    disk_autoresize   = var.database_disk_autoresize
    ip_configuration {
      ipv4_enabled    = var.database_ipv4_enabled
      private_network = google_compute_network.vpcnetwork[count.index].id
    }
}
  encryption_key_name = google_kms_crypto_key.cloudsql_crypt_key.id   

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


# #############################################  COMPUTE REGION INSTANCE TEMPLATE #############################################

resource "google_compute_region_instance_template" "vm_template" {
  count                = var.vpc_count
  name                 = var.vm_template_name
  description          = "This template is used to create webapp server instances."
  instance_description = "description assigned to virtual machine instances"
  machine_type         = var.machine_type
  can_ip_forward       = false
  tags                 = ["web-servers"]

  disk {
    source_image = var.packer_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.wm_instance_boot_disk_size_gb # Boot disk size in GB
    disk_type    = var.wm_instance_boot_disk_type
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_crypt_key.id

    }
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

  timeout_sec         = var.health_check_timeout_seconds
  check_interval_sec  = var.health_check_check_interval_seconds
  healthy_threshold   = var.health_check_healthy_threshold_count
  unhealthy_threshold = var.health_check_unhealthy_threshold_count

  http_health_check {
    port               = var.health_check_port
    port_specification = var.health_check_port_specification
    # host               = "1.2.3.4"
    request_path = var.health_check_request_path
    #response     = ""
  }
  log_config {
    enable = var.health_check_enable_log
  }

}

################################## HEALTH CHECK FIREWALL ##################################
resource "google_compute_firewall" "health-check" {
  count = var.vpc_count
  name  = "fw-allow-health-check"
  allow {
    protocol = "tcp"
    ports    = var.health_check_firewall_allowed_ports # Replace with your health check ports
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpcnetwork[count.index].id
  priority      = var.health_check_firewall_priority
  source_ranges = var.health_check_firewall_source_ranges
  target_tags   = ["web-servers"]
}
######################################## REGION AUTOSCALAR ########################################

resource "google_compute_region_autoscaler" "autoscaler" {
  count  = var.vpc_count
  name   = "my-region-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.appserver[count.index].id

  autoscaling_policy {
    max_replicas    = var.autoscalar_max_replicas
    min_replicas    = var.autoscalar_min_replicas
    cooldown_period = var.autoscalar_cooldown_period

    cpu_utilization {
      target = var.autoscalar_cpu_utilization_target
    }
  }
}

######################################## COMPUTE INSTANCE GROUP MANAGER ########################################

resource "google_compute_region_instance_group_manager" "appserver" {
  name                      = "appserver-igm"
  count                     = var.vpc_count
  base_instance_name        = "webapp"
  region                    = var.region
  #distribution_policy_zones = ["us-east4-c"]
  version {
    instance_template = google_compute_region_instance_template.vm_template[count.index].self_link
  }

  named_port {
    name = var.instance_group_manager_port_name
    port = var.instance_group_manager_port_number
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
    domains = ["sjaiswal.me."]
  }
}

######################################## LOAD BALANCER ########################################

# backend subnet
resource "google_compute_subnetwork" "default" {
  count         = var.vpc_count
  name          = "backend-subnet"
  ip_cidr_range = var.ip_cidr_range
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
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.load_balancing_scheme
  port_range            = var.load_balancing_port_range
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
  load_balancing_scheme = var.load_balancing_scheme
  locality_lb_policy    = var.locality_lb_policy
  health_checks         = [google_compute_health_check.http-health-check.id]
  protocol              = var.backend_protocol
  session_affinity      = var.backend_session_affinity
  timeout_sec           = var.backend_timeout_sec
  backend {
    group           = google_compute_region_instance_group_manager.appserver[count.index].instance_group
    balancing_mode  = var.backend_balancing_mode
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
  name         = var.dns_record_set_name
  type         = var.dns_record_set_type
  ttl          = var.dns_record_set_ttl
  managed_zone = var.dns_managed_zone
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
  location = var.region
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_crypt_key.id
  }
  depends_on = [ google_kms_crypto_key_iam_binding.storage-binding ]
}

resource "google_storage_bucket_object" "cloudfunc_arch_name" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "function-source.zip"   
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
  ip_cidr_range = var.vpc_cidr_range
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
    max_instance_count = var.service_config_max_instance_count
    min_instance_count = var.service_config_min_instance_count
    available_memory   = "256M"
    timeout_seconds    = var.service_config_timeout_seconds
    environment_variables = {
      DB_USERNAME     = google_sql_user.cloudsql_user[count.index].name,
      DB_PASSWORD     = google_sql_user.cloudsql_user[count.index].password,
      DB_HOST         = google_sql_database_instance.cloudsql_instance[count.index].private_ip_address,
      DB_NAME         = google_sql_database.cloudsql_database[count.index].name,
      MAILGUN_API_KEY = var.MAILGUN_API_KEY,
      DB_PORT         = var.postgres_port
    }
    ingress_settings               = var.service_config_ingress_settings
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



resource "local_file" "output_file_data" {
  count          = var.vpc_count 
  content = jsonencode({
    db_host     = google_sql_database_instance.cloudsql_instance[count.index].ip_address
    db_password = google_sql_user.cloudsql_user[count.index].password
    service_acc = google_service_account.service_account.email
  })
  filename = "outputs.json"
}
