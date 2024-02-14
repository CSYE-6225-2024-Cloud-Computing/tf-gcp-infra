# tf-gcp-infra
<hr>

## Setting up Networking in Google Cloud with Terraform

This repository contains Terraform templates to set up networking resources such as Virtual Private Cloud (VPC), subnets, routes, and more in Google Cloud Platform.

### Setup Instructions

1. **Download the Google Cloud SDK:**
   - Visit the [Google Cloud SDK download page](https://cloud.google.com/sdk/docs/install).
   - Choose the appropriate version for your operating system.
   - Follow the installation instructions provided.

2. **Install Terraform:**
   - Install Terraform by following the instructions [here](https://learn.hashicorp.com/tutorials/terraform/install-cli).

3. **Clone this Repository:**
   - Fork this repository to your GitHub account.
   - Clone the forked repository to your local machine.

4. **Enable GCP Service APIs:**
   - Enable the necessary Google Cloud Platform services (APIs) for your project. Refer to Google Cloud Console for detailed instructions.
   - Enabled APIs 
        - **Compute Engine API**
        - **Cloud OS login API**

5. **Google Cloud Platform Networking Setup:**
   - Follow the networking setup guidelines provided in the README.md file.
   - Create a Virtual Private Cloud (VPC) with specified configurations.
   - Set up subnets and routes according to the requirements.

6. **Infrastructure as Code with Terraform:**
   - Utilize Terraform configuration files to automate the setup and teardown of networking resources.
   - Ensure that no hard-coded values are present in your Terraform templates.
   - Your Terraform configuration should support creating multiple VPCs and its resources within the same GCP project and region.

### Directory Structure

tf-gcp-infra/
│
├── main.tf # Main Terraform configuration file
├── variables.tf # Define Terraform variables
├── outputs.tf # Define Terraform outputs
├── README.md # Detailed instructions for setup
└── .gitignore # Git ignore file