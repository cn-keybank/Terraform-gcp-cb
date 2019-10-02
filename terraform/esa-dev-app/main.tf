data "terraform_remote_state" "org-properties" {
  backend = "gcs"
  config = {
    bucket = "keto-org-terraform-254518-tfstate"
    prefix = "org-terraform"
  }
}

data "terraform_remote_state" "network-project" {
  backend = "gcs"
  config = {
    bucket = data.terraform_remote_state.org-properties.outputs.dev-terraform-state-bucket-name
    prefix = "Shared-Services/Shared-VPC/network-dev-sharedvpc/keto-gcp-dev-sharedvpc"
  }
}

module "esa-dev-app" {
  source            = "github.com/terraform-google-modules/terraform-google-project-factory.git?ref=v3.3.0"
  random_project_id = true
  name              = var.project
  org_id            = var.organization_id
  billing_account   = var.billing_account
  folder_id         = data.terraform_remote_state.org-properties.outputs.esa-dev-folder
  credentials_path  = local.credentials_file_path
  shared_vpc        = data.terraform_remote_state.network-project.outputs.project_id
  activate_apis = [
    "compute.googleapis.com",
    "iap.googleapis.com"
  ]
}

resource "google_compute_project_metadata_item" "oslogin" {
  project = module.esa-dev-app.project_id
  key     = "enable-oslogin"
  value   = "TRUE"
}

//resource "google_compute_instance" "vm2" {
//  project      = module.esa-dev-app.project_id
//  name         = "${local.instance_name}-2"
//  machine_type = "n1-standard-1"
//  zone         = random_shuffle.zone.result[0]
//
//  network_interface {
//    subnetwork         = "dev-subnet-01"
//    subnetwork_project = data.terraform_remote_state.network-project.outputs.project_id
//    access_config {}
//  }
//  boot_disk {
//    initialize_params {
//      image = "debian-cloud/debian-9"
//    }
//  }
//  metadata_startup_script = "echo hi > /test.txt"
//
//  tags = ["vm-example"]
//
//
//  service_account {
//    email = module.esa-dev-app.service_account_email
//    scopes = [
//      "https://www.googleapis.com/auth/cloud-platform",
//    ]
//  }
//}

resource "google_compute_instance" "vm" {
  project      = module.esa-dev-app.project_id
  name         = local.instance_name
  machine_type = "n1-standard-1"
  zone         = random_shuffle.zone.result[0]

  network_interface {
    subnetwork         = data.terraform_remote_state.network-project.outputs.subnets[0]
    subnetwork_project = data.terraform_remote_state.network-project.outputs.project_id
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  metadata_startup_script = "echo hi > /test.txt"

  tags = ["vm-example"]


  service_account {
    email = module.esa-dev-app.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
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
  instance_name         = var.instance_name
}

data "google_compute_zones" "available" {
  project = module.esa-dev-app.project_id
  region  = var.region
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

