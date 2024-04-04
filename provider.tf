terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>5"
    }
  }
}

#Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}
