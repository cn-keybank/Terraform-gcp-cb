terraform {
  backend "gcs" {
    bucket = "keto-org-terraform-254518-tfstate"
    prefix = "org-terraform"
  }
}
