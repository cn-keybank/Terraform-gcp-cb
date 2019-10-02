output "dev-terraform-state-bucket-resource" {
  value = module.dev-terraform-state-bucket.bucket
}

output "dev-terraform-state-bucket-name" {
  value = module.dev-terraform-state-bucket.name
}

output "dev-terraform-project-id" {
  value = module.dev-terraform-project.project_id
}

output "dev-terraform-kms-keyring-selflink" {
  value = module.dev-terraform-kms.keyring
}

output "dev-terraform-kms-keyring-name" {
  value = module.dev-terraform-kms.keyring_name
}


output "dev-terraform-kms-keys" {
  value = module.dev-terraform-kms.keys
}

output "dev-network-shared-service-folder" {
  value = google_folder.shared-vpc-dev.name
}

output "esa-dev-folder" {
  value = google_folder.esa-dev.name
}

