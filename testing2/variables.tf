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

# variable "project" {
#   type        = string
#   description = "GCP Project ID"
#   default     = "your-gcp-project-id"
# }

variable "region" {
  type        = string
  description = "GCP Region for this infrastructure"
  default     = "us-central1"
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
  default     = "us-central1-a"
}

variable "packer_image" {
  type        = string
  description = "Custom image name for boot disk"
  default     = "centos-8-packer-20240224094059" #centos-8-packer-20240221044109
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

