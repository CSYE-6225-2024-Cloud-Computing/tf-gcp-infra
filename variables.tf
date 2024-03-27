variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  default     = "dev-gcp-project-414615"
}

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


variable "region" {
  type        = string
  description = "GCP Region for this infrastructure"
  default     = "us-west1"
}

variable "subnet_webapp_name" {
  type        = list(string)
  description = "A list of names for the webapp subnets"
  default = ["webapp1","webapp2"]
}

variable "subnet_CIDR_webapp" {
  type        = list(string)
  description = "CIDR ranges of webapp subnets"
  default  = ["10.10.10.0/24", "10.10.20.0/24"]
}

variable "subnet_db_name" {
  type        = list(string)
  description = "A list of names for the db subnets"
  default = ["db1","db2"]
}

variable "subnet_CIDR_db" {
  type        = list(string)
  description = "CIDR ranges of database subnets"
  default  = ["10.10.30.0/24", "10.10.40.0/24"]
}

variable "webapp_route" {
  type        = string
  description = "Name of webapp route"
  default     = "webapp-route"
}

variable "my_instance_name" {
  type        = string
  description = "Name of the Compute Engine instance"
  default     = "my-instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type for Compute Engine instance"
  default     = "n1-standard-1"
}

variable "zone" {
  type        = string
  description = "GCP Zone for Compute Engine instance"
  default     = "us-west1-b"
}

variable "packer_image" {
  type        = string
  description = "Custom image name for boot disk"
  default     = "centos-8-packer-20240327092458" #centos-8-packer-20240327021420 
}

variable "initialize_params_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 100
}

variable "initialize_params_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-balanced"
}

variable "server_port" {
  type        = number
  description = "Application server port"
  default     = 8000
}

variable "script_path" {
  type        = string
  description = "Path to startup.sh script"
  default     = "./startup.sh"
}

variable "postgres_db" {
  type        = string
  description = "PostgreSQL database name"
  default     = "test01"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL database username"
  default     = "postgres"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL database password"
  default     = "postgres"
}

variable "postgres_uri" {
  type        = string
  description = "PostgreSQL database URI"
  default     = "localhost"
}

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

variable "app_password" {
  type        = string
  description = "Application password"
  default     = "csye6225"
}

variable "app_group" {
  type        = string
  description = "Application group"
  default     = "csye6225"
}

variable "app_dir" {
  type        = string
  description = "Application directory"
  default     = "/var/www/webapp"
}

variable "env_dir" {
  type        = string
  description = "Environment directory"
  default     = "/home/csye6225/webapp/.env"
}

variable "routing_mode" {
  type        = string
  description = "Routing Mode"
  default     = "REGIONAL"
}

variable "db_password" {
  type        = string
  description = "Custom image name for boot disk"
  default     = "test1234"
}


variable "deletion_protection" {
  description = "Enable or disable deletion protection for Cloud SQL instances"
  type        = bool
  default     = false
}

variable "disk_type" {
  description = "Disk type for Cloud SQL instances"
  type        = string
  default     = "pd-ssd"
}

variable "disk_size" {
  description = "Disk size for Cloud SQL instances"
  type        = number
  default     = 100
}

variable "disk_autoresize" {
  description = "Enable or disable automatic disk resizing for Cloud SQL instances"
  type        = bool
  default     = true
}


variable "ipv4_enabled" {
  description = "Enable or disable IPv4 for Cloud SQL instances"
  type        = bool
  default     = false
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "csye6225-cloudsql-instance"
}

variable "database_version" {
  description = "Database version for Cloud SQL instances"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Tier for Cloud SQL instances"
  type        = string
  default     = "db-f1-micro"
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


# Variable for the name of the managed DNS zone
variable "managed_zone_name" {
  type        = string
  description = "Name of the managed DNS zone"
  default     = "csye-zone"
}

# Variable for the DNS name associated with the managed zone
variable "dns_name" {
  type        = string
  description = "DNS name associated with the managed zone"
  default     = "sjaiswal.me."
}

# Variable for the name of the DNS record set
variable "record_set_name" {
  type        = string
  description = "Name of the DNS record set"
  default     = "csye6225-zone"
}

# Variable for the TTL (Time To Live) for the DNS record set
variable "record_set_ttl" {
  type        = number
  description = "TTL for the DNS record set"
  default     = 300
}

# Variable for the IP address of the Google Compute Engine instance
variable "compute_instance_ip" {
  type        = string
  description = "IP address of the Google Compute Engine instance"
  default     = "10.0.0.1"  # Update with the actual IP address
}

########################### PUB/SUB Variables ##############################

variable "pubsub_topic"{
  description = "pubsub topic"
  type        = string
  default     = "verify_email"
}

variable "retention_time"{
  description = "retention_time"
  type        = string
  default     = "604800s"
}

variable "pubsub_publisher"{
  description = "pubsub.publisher"
  type        = string
  default     = "roles/pubsub.publisher"
}

########################### Bucket and files Variables ##############################

variable "cloud_platform_scope" {
  description = "The scope for the service account, such as 'cloud-platform'."
  type        = string
  default     = "cloud-platform"
}

variable "bucket_location"{
  description = "pubsub location"
  type        = string
  default     = "US"
}

variable "archive_output_path"{
  description = "archive_file"
  type        = string
  default     = "/tmp/serverless-fork.zip"
}

variable "archive_source_file"{
  description = "archive_file"
  type        = string
  default     = "/Users/shreyajaiswal/Downloads/serverless-fork" 
}

variable "archive_file_name"{
  description = "archive_file"
  type        = string
  default     = "serverless-fork.zip"
}

########################### Cloud Function Variables ##############################
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

variable "cloud_function_timeout"{
  description = "cloud_function_timeout"
  type        = number
  default     = 60
}

variable "cloud_function_object"{
  description = "cloud_function_object"
  type        = string
  default     = "function-source.zip"
}


variable "cloud_function_role"{
  description = "cloud_function_role"
  type        = string
  default     = "roles/viewer"
}


########################### ENV Variables ##############################
variable "MAILGUN_API_KEY"{
  description = "mailgun-api-key"
  type        = string
  default     = "4de658fabd37ad41a0cc1666f49e8e51-f68a26c9-ab63ee66"
}

variable "connector_name" {
  description = "Name of the VPC Network Connector in GCP"
  type        = string
  default     = "vpc_conn"
}

