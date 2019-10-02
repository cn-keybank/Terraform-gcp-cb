/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  credentials_file_path = var.credentials_path
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

// Root Folders
resource "google_folder" "shared-services" {
  display_name = "Shared Services"
  parent       = var.root_id
}

resource "google_folder" "data-program" {
  display_name = "Data Program"
  parent       = var.root_id
}

// Shared Services sub-folders
resource "google_folder" "shared-vpc" {
  display_name = "Shared VPC"
  parent       = google_folder.shared-services.id
}
resource "google_folder" "shared-vpc-dev" {
  display_name = "network-dev-sharedvpc"
  parent       = google_folder.shared-vpc.id
}
resource "google_folder" "shared-vpc-np" {
  display_name = "network-np-sharedvpc"
  parent       = google_folder.shared-vpc.id
}
resource "google_folder" "shared-vpc-prod" {
  display_name = "network-prod-sharedvpc"
  parent       = google_folder.shared-vpc.id
}

// End shared VPC sub-folders
resource "google_folder" "terraform" {
  display_name = "Terraform"
  parent       = google_folder.shared-services.id
}

resource "google_folder" "logging" {
  display_name = "Logging"
  parent       = google_folder.shared-services.id
}

resource "google_folder" "billing" {
  display_name = "Billing"
  parent       = google_folder.shared-services.id
}
resource "google_folder" "data-supply-chain" {
  display_name = "Data Supply Chain"
  parent       = google_folder.shared-services.id
}

// data program sub-folders

resource "google_folder" "esa" {
  display_name = "ESA"
  parent       = google_folder.data-program.id
}
resource "google_folder" "esa-dev" {
  display_name = "keto-esa-dev"
  parent       = google_folder.esa.id
}


resource "google_folder" "xyz" {
  display_name = "XYZ"
  parent       = google_folder.data-program.id
}
resource "google_folder" "xyz-dev" {
  display_name = "keto-xyz-dev"
  parent       = google_folder.xyz.id
}

module "org_teraform_iam_bindings" {
  source = "github.com/terraform-google-modules/terraform-google-iam.git?ref=master"

  # Allow TF service accounts to read org state.
  # This is for remote state access
  storage_buckets_num          = 1
  storage_buckets_bindings_num = 1
  storage_buckets = [
    var.org_state_bucket
  ]
  storage_buckets_bindings = {
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com",
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
  }

  organizations              = []
  organizations_num          = 0
  organizations_bindings_num = 0
  organizations_bindings     = {}

  folders_num          = 0
  folders              = []
  folders_bindings_num = 0
  folders_bindings     = {}

  projects              = []
  projects_num          = 0
  projects_bindings_num = 0
  projects_bindings     = {}

  service_accounts_bindings     = {}
  kms_key_rings_bindings        = {}
  pubsub_topics_bindings        = {}
  kms_crypto_keys               = []
  kms_crypto_keys_num           = 0
  kms_crypto_keys_bindings_num  = 0
  kms_crypto_keys_bindings      = {}
  subnets_bindings              = {}
  pubsub_subscriptions_bindings = {}

  subnets_region = var.region
}
