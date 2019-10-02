data "terraform_remote_state" "org-properties" {
  backend = "gcs"
  config = {
    bucket = "keto-org-terraform-254518-tfstate"
    prefix = "org-terraform"
  }
}

module "dev-vpc" {
  source       = "github.com/terraform-google-modules/terraform-google-network.git?ref=master"
  project_id   = module.network-dev-sharedvpc.project_id
  network_name = "dev-vpc"

  shared_vpc_host                        = true
  delete_default_internet_gateway_routes = true

  subnets = [
    {
      subnet_name   = "${local.subnet_01}"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
    {
      subnet_name           = "${local.subnet_02}"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
    },
  ]
}

resource "google_compute_router" "dev-router" {
  name    = "dev-router"
  region  = var.region
  project = module.network-dev-sharedvpc.project_id
  network = module.dev-vpc.network_name
}

module "cloud-nat" {
  source     = "github.com/terraform-google-modules/terraform-google-cloud-nat.git"
  router     = google_compute_router.dev-router.name
  project_id = module.network-dev-sharedvpc.project_id
  region     = var.region
  name       = "dev-cloud-nat"
}

resource "google_compute_firewall" "allow-iap-ssh" {
  name    = "allow-iap-ssh"
  project = module.network-dev-sharedvpc.project_id
  network = module.dev-vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}


module "network-dev-sharedvpc" {
  source            = "github.com/terraform-google-modules/terraform-google-project-factory.git?ref=v3.3.0"
  random_project_id = true
  name              = var.project
  org_id            = var.organization_id
  billing_account   = var.billing_account
  folder_id         = data.terraform_remote_state.org-properties.outputs.dev-network-shared-service-folder
  credentials_path  = local.credentials_file_path
}


/******************************************
  Provider configuration
 *****************************************/
provider "google" {
  credentials = file(local.credentials_file_path)
  version     = "~> 2.16"
}

provider "google-beta" {
  credentials = file(local.credentials_file_path)
  version     = "~> 2.16"
}
locals {
  credentials_file_path = var.credentials_path
  subnet_01             = "dev-subnet-01"
  subnet_02             = "dev-subnet-02"
}
