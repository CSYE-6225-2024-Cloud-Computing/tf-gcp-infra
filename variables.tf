######################################## PROJECT VARIABLES ##########################################
variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  default     = "dev-gcp-project-414615"
}

variable "region" {
  type        = string
  description = "GCP Region for this infrastructure"
  default     = "us-east4" #"us-central1"
}

variable "zone" {
  type        = list(string)
  description = "GCP Zone for Compute Engine instance"
  default     = ["us-east4-c"] #"us-central1-a"
}

######################################## VPC VARIABLES #############################################
variable "vpc_count" {
  type        = number
  description = "Number of VPCs to create"
  default     = 1
}

variable "vpc_names" {
  type        = list(string)
  description = "Names of the VPCs"
  default     = ["vpc-1", "vpc-2"]
}

variable "auto_create_subnetworks" {
  description = "auto_create_subnetworks"
  type        = bool
  default     = false
}

variable "routing_mode" {
  type        = string
  description = "Routing Mode"
  default     = "REGIONAL"
}

######################################## FIREWALL VARIABLES #############################################
variable "allow_protocol" {
  description = "allow protocol"
  type        = string
  default     = "tcp"
}

variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(string)
  default     = ["80", "8000"]
}


variable "allow_priority" {
  description = "Priority for the deny-all-traffic firewall rule"
  type        = number
  default     = 1000
}

variable "deny_priority" {
  description = "Priority for the deny-all-traffic firewall rule"
  type        = number
  default     = 1200
}

variable "deny_protocol" {
  description = "deny_protocol"
  type        = string
  default     = "all"
}

######################################## SUBNET WEBAPP VARIABLES #############################################
variable "subnet_webapp_name" {
  type        = list(string)
  description = "A list of names for the webapp subnets"
  default     = ["webapp1", "webapp2"]
}

variable "subnet_CIDR_webapp" {
  type        = list(string)
  description = "CIDR ranges of webapp subnets"
  default     = ["10.10.10.0/24", "10.10.20.0/24"]
}
######################################## GLOBAL ADDRESS AND NETWORKING  CONNECTION #############################################
variable "private_ip_address_purpose" {
  description = "Purpose of the private IP address"
  type        = string
  default     = "VPC_PEERING"
}

variable "private_ip_address_type" {
  description = "Type of the private IP address"
  type        = string
  default     = "INTERNAL"
}

variable "private_ip_address_prefix_length" {
  description = "Prefix length of the private IP address"
  type        = number
  default     = 16
}


variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "servicenetworking.googleapis.com"
}

# ############################################# WEBAPP ROUTE VARIABLES ############################################

variable "webapp_route" {
  type        = string
  description = "Name of webapp route"
  default     = "webapp-route"
}

variable "webapp_route_dest_range" {
  description = "webapp_route_dest_range"
  type        = string
  default     = "0.0.0.0/0"
}

variable "webapp_route_next_hop_gateway" {
  description = "webapp_route_next_hop_gateway"
  type        = string
  default     = "global/gateways/default-internet-gateway"
}

# #############################################  SERVICE ACCOUNT VARIABLES #############################################
variable "metric_writer_role" {
  description = "The role assigned to the service account for metric writing."
  default     = "roles/monitoring.metricWriter"
}

variable "logging_admin_role" {
  description = "The role assigned to the service account for logging administration."
  default     = "roles/logging.admin"
}

# ############################################# GOOGLE SQL DATABASE INSTANCE VARIABLES###################################
variable "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "csye6225-cloudsql-instance"
}

variable "database_version" {
  description = "Database version for Cloud SQL instances"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_deletion_protection" {
  description = "Enable or disable deletion protection for Cloud SQL instances"
  type        = bool
  default     = false
}

variable "database_tier" {
  description = "Tier for Cloud SQL instances"
  type        = string
  default     = "db-f1-micro" #"db-custom-2-7680" #"db-f1-micro" #
}


variable "database_disk_type" {
  description = "Disk type for Cloud SQL instances"
  type        = string
  default     = "pd-ssd"
}

variable "databse_disk_size" {
  description = "Disk size for Cloud SQL instances"
  type        = number
  default     = 100
}

variable "database_disk_autoresize" {
  description = "Enable or disable automatic disk resizing for Cloud SQL instances"
  type        = bool
  default     = true
}

variable "database_ipv4_enabled" {
  description = "Enable or disable IPv4 for Cloud SQL instances"
  type        = bool
  default     = false
}

variable "cloudsql_database_name" {
  description = "Name of the database to be created in Cloud SQL"
  type        = string
  default     = "webapp"
}

variable "cloudsql_user_name" {
  description = "Name of the user to be created in Cloud SQL"
  type        = string
  default     = "webapp"
}

#######################################  COMPUTE REGION INSTANCE TEMPLATE  VARIABLES#############################################
variable "vm_template_name" {
  description = "Name of the VM template to be created"
  type        = string
  default     = "webapp-template"
}
variable "machine_type" {
  type        = string
  description = "Machine type for Compute Engine instance"
  default     = "n1-standard-2"
}

variable "wm_instance_boot_disk_size_gb" {
  type        = number
  description = "Boot disk size in GB"
  default     = 30
}

variable "wm_instance_boot_disk_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-balanced"
}

#metadata_startup_script_variables
variable "postgres_port" {
  type        = number
  description = "PostgreSQL database port"
  default     = 5432
}

variable "app_user" {
  type        = string
  description = "Application user"
  default     = "csye6225"
}


variable "app_group" {
  type        = string
  description = "Application group"
  default     = "csye6225"
}

variable "packer_image" {
  type        = string
  description = "Custom image name for boot disk"
  default     = "centos-8-packer-20240403070957" #centos-8-packer-20240409033206
}


########################################### HEALTH CHECK VARIABLES ###########################################
variable "health_check_timeout_seconds" {
  type        = number
  description = "The amount of time, in seconds, for which the health check can wait to receive a response from the instance."
  default     = 5
}

variable "health_check_check_interval_seconds" {
  type        = number
  description = "How often (in seconds) to send a health check request."
  default     = 15
}

variable "health_check_healthy_threshold_count" {
  description = "The number of consecutive health check successes required before moving the instance to the healthy state."
  default     = 4
}

variable "health_check_unhealthy_threshold_count" {
  type        = number
  description = "The number of consecutive health check failures required before moving the instance to the unhealthy state."
  default     = 4
}

variable "health_check_port" {
  type        = number
  description = "The TCP port number for the health check request."
  default     = 8000
}

variable "health_check_port_specification" {
  type        = string
  description = "The port specification for the health check."
  default     = "USE_FIXED_PORT"
}

variable "health_check_request_path" {
  type        = string
  description = "The HTTP request path to use for the health check."
  default     = "/healthz/"
}

variable "health_check_enable_log" {
  type        = bool
  description = "Enable logging for the health check."
  default     = true
}

################################## HEALTH CHECK FIREWALL VARIABLES##################################
variable "health_check_firewall_allowed_ports" {
  type        = list(string)
  description = "List of ports to allow for health check."
  default     = ["80", "443", "8000"]
}

variable "health_check_firewall_priority" {
  type        = number
  description = "Priority of the firewall rule."
  default     = 1000
}

variable "health_check_firewall_source_ranges" {
  type        = list(string)
  description = "List of CIDR ranges to allow traffic from."
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}
######################################## REGION AUTOSCALAR VARIABLES ########################################
variable "autoscalar_max_replicas" {
  type        = number
  description = "Maximum number of replicas to scale to."
  default     = 2
}

variable "autoscalar_min_replicas" {
  type        = number
  description = "Minimum number of replicas to maintain."
  default     = 1
}

variable "autoscalar_cooldown_period" {
  type        = number
  description = "Cooldown period in seconds between scaling actions."
  default     = 60
}

variable "autoscalar_cpu_utilization_target" {
  type        = number
  description = "Target CPU utilization for autoscaling."
  default     = 0.05
}
####################################### COMPUTE INSTANCE GROUP MANAGER VARIABLES ########################################

variable "instance_group_manager_port_name" {
  type        = string
  description = "Named port of the instance group manager."
  default     = "http"
}

variable "instance_group_manager_port_number" {
  type        = number
  description = "port number of the instance group manager."
  default     = 8000
}
######################################## LOAD BALANCER VARIABLES########################################
# forwarding rule

variable "ip_cidr_range" {
  description = "ip_cidr_range"
  type        = string
  default     = "10.1.2.0/24"
}

variable "load_balancing_scheme" {
  description = "Load balancing scheme for the forwarding rule"
  type        = string
  default     = "EXTERNAL_MANAGED"
}

variable "load_balancing_port_range" {
  description = "Port range for the forwarding rule"
  type        = string
  default     = "443"
}

variable "ip_protocol" {
  description = "allow protocol"
  type        = string
  default     = "TCP"
}

# backend service with custom request and response headers
variable "locality_lb_policy" {
  description = "Locality-based load balancing policy for the backend service"
  type        = string
  default     = "ROUND_ROBIN"
}

variable "backend_protocol" {
  description = "Protocol for the backend service"
  type        = string
  default     = "HTTP"
}

variable "backend_session_affinity" {
  description = "Session affinity for the backend service"
  type        = string
  default     = "NONE"
}

variable "backend_timeout_sec" {
  description = "Timeout in seconds for the backend service"
  type        = number
  default     = 30
}

variable "backend_balancing_mode" {
  description = "Balancing mode for the backend service"
  type        = string
  default     = "UTILIZATION"
}

############################################## GOOGLE DNS RECORD SET VARIABLES #############################################
variable "dns_record_set_name" {
  description = "Name of the DNS record set"
  type        = string
  default     = "sjaiswal.me."
}
variable "dns_record_set_type" {
  description = "Type of the DNS record set"
  type        = string
  default     = "A"
}

variable "dns_record_set_ttl" {
  description = "Time to live (TTL) for the DNS record set in seconds"
  type        = number
  default     = 21600
}

variable "dns_managed_zone" {
  description = "Managed zone for the DNS record set"
  type        = string
  default     = "csye-zone"
}

############################################## PUB/SUB - TOPIC VARIABLES #############################################
variable "pubsub_topic" {
  description = "pubsub topic"
  type        = string
  default     = "verify_email"
}

variable "retention_time" {
  description = "retention_time"
  type        = string
  default     = "604800s"
}

variable "pubsub_publisher" {
  description = "pubsub.publisher"
  type        = string
  default     = "roles/pubsub.publisher"
}
########################################### VPC CONNECT  VARIABLES #############################################
variable "vpc_cidr_range" {
  type    = string
  default = "10.8.0.0/28" # Add or modify CIDR ranges as needed
}
########################################### Cloud Function VARIABLES ###########################################
variable "cloud_function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "cloud-function-webapp"
}

variable "cloud_runtime" {
  description = "Runtime for the Cloud Function"
  type        = string
  default     = "python39"
}

variable "cloud_entry_point" {
  description = "Entry point for the Cloud Function"
  type        = string
  default     = "verify_useremail"
}

variable "cloud_event_type" {
  description = "Event type for the Cloud Function trigger"
  type        = string
  default     = "google.cloud.pubsub.topic.v1.messagePublished"
}

variable "cloud_retry_policy" {
  description = "Retry policy for the Cloud Function trigger"
  type        = string
  default     = "RETRY_POLICY_RETRY"
}

# variable "cloud_function_memory"{
#   description = "cloud_function_memory"
#   type        = number
#   default     = "256M"
# }

variable "cloud_function_timeout" {
  description = "cloud_function_timeout"
  type        = number
  default     = 60
}

variable "cloud_function_object" {
  description = "cloud_function_object"
  type        = string
  default     = "function-source.zip"
}

variable "service_config_max_instance_count" {
  description = "Time to live (TTL) for the DNS record set in seconds"
  type        = number
  default     = 3
}

variable "service_config_min_instance_count" {
  description = "Time to live (TTL) for the DNS record set in seconds"
  type        = number
  default     = 1
}

variable "service_config_timeout_seconds" {
  description = "Time to live (TTL) for the DNS record set in seconds"
  type        = number
  default     = 60
}

variable "service_config_ingress_settings" {
  description = "cloud_function_role"
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"
}
variable "cloud_function_role" {
  description = "cloud_function_role"
  type        = string
  default     = "roles/viewer"
}
########################### ENV Variables ##############################
variable "MAILGUN_API_KEY" {
  description = "mailgun-api-key"
  type        = string
  default     = "4de658fabd37ad41a0cc1666f49e8e51-f68a26c9-ab63ee66"
}

variable "connector_name" {
  description = "Name of the VPC Network Connector in GCP"
  type        = string
  default     = "vpc_conn"
}
