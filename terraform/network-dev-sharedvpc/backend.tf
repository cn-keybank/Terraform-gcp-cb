terraform {
  backend "gcs" {
    bucket = "keto-terraform-b958-us-dev-state-bucket"
    prefix = "Shared-Services/Shared-VPC/network-dev-sharedvpc/keto-gcp-dev-sharedvpc"
  }
}
