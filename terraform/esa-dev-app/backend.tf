terraform {
  backend "gcs" {
    bucket = "keto-terraform-b958-us-dev-state-bucket"
    prefix = "Data-Program/ESA/esa-dev/esa-dev-app"
  }
}
