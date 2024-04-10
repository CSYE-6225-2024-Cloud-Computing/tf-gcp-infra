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

