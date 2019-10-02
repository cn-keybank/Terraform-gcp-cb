/**
 * Seed Project for this folder and below the hierarchy
 * including IAM bindings needed
 */
resource "random_id" "dev-terraform-suffix" {
  byte_length = 2
}

module "dev-terraform-project" {
  source            = "github.com/terraform-google-modules/terraform-google-project-factory.git?ref=v3.3.0"
  random_project_id = true
  name              = "keto-gcp-dev-terraform"
  org_id            = var.organization_id
  billing_account   = var.billing_account
  folder_id         = google_folder.terraform.id
  credentials_path  = local.credentials_file_path
  activate_apis = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "appengine.googleapis.com",
    "admin.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
  ]
}

// Service account for Dev Terraform
resource "google_service_account" "dev-terraform-master" {
  project    = "${module.dev-terraform-project.project_id}"
  account_id = "dev-terraform-master-${random_id.dev-terraform-suffix.hex}"
}

// Below are the IAM bindings related to the Dev Terraform CloudBuild runs
// These are the permissions necessary for the Dev Terraform Cloudbuils to
// manage Dev Resources
module "dev_terraform_iam_bindings" {
  source = "github.com/terraform-google-modules/terraform-google-iam.git?ref=master"

  organizations              = [var.organization_id]
  organizations_bindings_num = 1

  // Allow reading Organization info
  organizations_bindings = {
    "roles/resourcemanager.organizationViewer" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
  }

  folders_num = 3

  // Apply the following IAM permissions for each dev namespaced folder
  folders = [
    replace(google_folder.shared-vpc-dev.name, "folders/", ""),
    replace(google_folder.esa-dev.name, "folders/", ""),
    replace(google_folder.xyz-dev.name, "folders/", "")
  ]

  folders_bindings_num = 9
  folders_bindings = {
    // Allow Viewing all resources inside these folders
    "roles/resourcemanager.folderViewer" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Allow creating projects in these folder
    "roles/resourcemanager.projectCreator" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Manage service account resources in these folders
    "roles/iam.serviceAccountAdmin" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Create additional folders in these Folders
    "roles/resourcemanager.folderCreator" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Move sub-folders
    "roles/resourcemanager.folderMover" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Administer networks inside these folders
    "roles/compute.networkAdmin" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Administer Shared/Host VPCs inside these folders
    "roles/compute.xpnAdmin" = [
      "serviceAccount:${google_service_account.dev-terraform-master.email}"
    ]
    // Allow Root SSH Logins for compute resources inside these folders
    "roles/compute.osAdminLogin" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
    // Allow access to IAP for TCP tunnels: Used for SSH'ing to compute resources
    "roles/iap.tunnelResourceAccessor" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
  }

  projects = [
    module.dev-terraform-project.project_id
  ]

  projects_bindings_num = 1
  // TODO: double check that this permission is still required.
  // Allow access to manage IAM permissions on the Dev Terraform Project. Granted to the CloudBuild Service Account
  projects_bindings = {
    "roles/resourcemanager.projectIamAdmin" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
  }

  storage_buckets_num          = 1
  storage_buckets_bindings_num = 2
  storage_buckets = [
    module.dev-terraform-state-bucket.name
  ]
  storage_buckets_bindings = {
    // Allow the CloudBuild Service Account the ability to create terraform remote state
    "roles/storage.objectCreator" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
    // Allow the CloudBuild Service Account the ability to view terraform remote state
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
  }
  service_accounts_bindings = {}
  kms_key_rings_bindings    = {}
  pubsub_topics_bindings    = {}
  kms_crypto_keys = [
    module.dev-terraform-kms.keys["dev-terraform-master"]
  ]
  kms_crypto_keys_num          = 1
  kms_crypto_keys_bindings_num = 1
  kms_crypto_keys_bindings = {
    // Allow the CloudBuild Service Account the ability to decrypt with the
    // dev-terraform KMS key. Used for decrypting the Dev Terraform Service
    // Account credentials
    "roles/cloudkms.cryptoKeyDecrypter" = [
      "serviceAccount:${module.dev-terraform-project.project_number}@cloudbuild.gserviceaccount.com"
    ]
  }
  subnets_bindings              = {}
  pubsub_subscriptions_bindings = {}

  subnets_region = var.region

}

// Billing Account User
// Allows the Dev Terraform Service Account the ability to assign Billing Accounts to projects
resource "google_billing_account_iam_member" "billingaccountuser-binding" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.dev-terraform-master.email}"
}

// KMS Key
module "dev-terraform-kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 1.0"

  project_id = module.dev-terraform-project.project_id
  location   = "global"
  keys       = ["dev-terraform-master"]
  keyring    = "dev-terraform"
}

module "dev-terraform-state-bucket" {
  source     = "github.com/terraform-google-modules/terraform-google-cloud-storage.git?ref=master"
  project_id = module.dev-terraform-project.project_id
  location   = "US"
  names      = ["dev-state-bucket"]
  prefix     = "keto-terraform-${random_id.dev-terraform-suffix.hex}"
  versioning = {
    state-bucket = true
  }
}

// TODO: create cloudbuild resources??
