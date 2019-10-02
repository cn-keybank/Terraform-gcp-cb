# CloudBuild+Terraform CICD Demo

## Before starting

If you plan to build this demo yourself, the first thing to do is Fork this
repository. There are many values that must be changed for your GCP
Organization including the `backend.tf`, terraform.tfvars, and all encrypted
files in the `secrets/` directory.

## Component Overview

* Bitbucket Git Repository: Infrastructure-as-Code repository
* Terraform: Tool for executing IaC
* GCP Cloud Build: Execute Terraform + Containers/Commands
* GCP KMS: Encrypt/Decrypt Service Account Credentials
* GCP Cloud Storage: Remote Terraform State Storage
* GCP IAM: Terraform Service Accounts and Permission Policies

## Bootstrapping

At a high level, bootstrapping works like this:

1. An Organization Admin creates a special Terraform project (sometimes called the "Seed" project)
2. An Organization Admin sets up a GCS bucket, a KMS Key, and uses the included helper script to set up a Terraform Service Account and download a `credentials.json` file
3. Fork this repository and configure the following files to reflect your Organization settings
    1. `terraform/keto-organization/backend.tf`: Update `bucket`
    2. `terraform/keto-organization/terraform.tfvars`: Update `project`, `organization`, `root_id`, `billing_account`, `org_state_bucket`
    3. `terraform/keto-organization/cloudbuild.yaml`: KMS keyring and key name
    4. `secrets/keto-organization-sa.json.enc` :using KMS to encrypt `credentials.json` file
4. An Organization Admin sets up a Cloud Source repository with your fork -- either by mirroring or `git push`
5. An Organization Admin creates a CloudBuild trigger
6. Build the `terraform/keto-organization` with CloudBuild
7. Using resources from the newly created Dev Terraform project, configure the other resources
    1. `terraform/network-dev-sharedvpc/backend.tf`: Use the GCS bucket created in step 6
    2. `terraform/network-dev-sharedvpc/terraform.tfvars`: Update the `organization_id`, `billing_account` for your organization
    3. `secrets/keto-gcp-dev-terraform.json.enc`: Update with KMS encrypted credentials.json for the Dev Terraform service account. Make sure to use the KMS key that was created in step 6 
    4. Set up CloudBuild triggers in the Terraform Dev project similar to step 4 and step 5
8. Repeat step 7.1 and step 7.2 for `terraform/esa-dev-app`

More details for Administrators is below

### Before You Start: Administrator Permissions Required

To start with this demo you first must a Google Cloud account with access to a
GCP organization.

Your account must have the following permissions or you will not be able to
bootstrap this demo:

* resourcemanager.organizations.list
* resourcemanager.organizations.setIamPolicy
* resourcemanager.organizations.getIamPolicy
* resourcemanager.projects.list
* resourcemanager.projects.setIamPolicy
* billing.accounts.list
* servicemanagement.services.bind on following services:
	* cloudresourcemanager.googleapis.com
	* cloudbilling.googleapis.com
	* iam.googleapis.com
	* admin.googleapis.com
	* appengine.googleapis.com
* billing.accounts.getIamPolicy on a billing account.
* billing.accounts.setIamPolicy on a billing account.


### Organization Admin Instructions


After verifying your account permissions, create a new GCP project (call it
`terraform-org-management` or something similar). This project will be set up
to run the Org-level Terraform code. In the commands below, the project id is
referred to as `$PROJECT_ID`

In addition to the permissions previously mentioned, you must have the
following roles/permissions:

* iam.serviceAccounts.create on the project
* iam.serviceAccountKeys.create on the project
* serviceusage.services.enable on the project
* roles/cloudkms.admin
* roles/cloudbuild.builds.builder
* roles/storage.admin

Run the helper script included under the `helpers/` directory. This will create
the Terraform Service Account and activate the correct APIs. It will also
download a `credentials.json` file in the local directory.

This script takes 3 parameters: `organization id`, `project id`, and a `billing
account id` you can use


After running the script, create the following:

- GCS Bucket for storing state
	- `gsutil mb -p $PROJECT_ID "gs://$PROJECT_ID-tfstate"`
	- `gsutil versioning set on "gs://$PROJECT_ID-tfstate"`
- KMS Keyring and Key. Use global as your location
	- `gcloud --project $PROJECT_ID kms keyrings create org-terraform --location=global`
	- `gcloud --project $PROJECT_ID kms key create org-terraform-sa --purpose=encryption --keyring=org-terraform`

At this point you have the following configured,

- A Project containing the resources you need to manage Org-level resources with Terraform
- A Terraform Service Account with the correct permissions/roles and a `credentials.json` file
- GCS Bucket for keeping the Terraform remote state

### Re-configure terraform/keto-organization

Edit `terraform/keto-organization/backend.tf` and replace the
`bucket` parameter with the name of the bucket you previously
created

Edit `terraform/keto-organization/terraform.tfvars` and set the following variables:

- `project`: The `$PROJECT_ID`
- `organization_id`: The ID of your organization
- `billing_account`: The ID of the billing account to associate to projects
- `root_id`: The root of the folder structure. Use the
organization ID if you want to start creating folders at the root
of the organization. Use a folders ID if you want to create in a
specific folder
- `org_state_bucket`: The state bucket name

Edit `terraform/keto-organization/cloudbuild.yaml`. In the first step, make
sure that the KMS keyring and key match the name of the ones you created
earlier.

### Set up CloudBuild

- Encrypt the `credentials.json` file with the newly created key
	- `gcloud --project $PROJECT_ID kms encrypt --plainttext-file=credentials.json --ciphertext-file=secrets/keto-organization-sa.json.enc`
	- `rm credentials.json`

Commit and push all changes to your forked version of this repository.

This encrypted credentials file will be used by CloudBuild to activate the Terraform Service Account.

Navigate to the Cloud Console for `$PROJECT_ID` and find the CloudBuild console: <http://console.cloud.google.com/cloud-build/triggers>

Click `Connect Repository` at the top of the Triggers page and connect your
forked version of this repository. If your forked version is inaccessible to
GCP (if it's on-prem), you can workaround this by creating a Cloud Source
Repository and manually pushing changes to this. (TODO: add instructions on how
to automatically push to Cloud Source to keep repositories synced)

After the repository is synced to Cloud Source Repository, it should show up on
the Triggers page to create a Trigger. Create a new Trigger, give it a name,
and description, use Trigger type: branch and set Branch (regex) to `master`

Under Build Configuration, set to `Cloud Build configuration` and set to
`/terraform/keto-organization/cloudbuild.yaml`

Save.

After CloudBuild runs for the first time, it should create the Folder structure
and a `dev-terraform` project under `Shared Services/Terraform`



## Related Links

* [Centralized SSH Login with OSLogin](https://medium.com/infrastructure-adventures/centralized-ssh-login-to-google-compute-engine-instances-d00f8654f379)
* [IAM Role Documentation](https://cloud.google.com/iam/docs/understanding-roles)
* [Identity-Aware Proxy: Login as Root using an IAM Role ](https://cloud.google.com/compute/docs/instances/connecting-advanced#root)
* [Infrastructure As Code: Terraform, Cloud Build](https://cloud.google.com/solutions/managing-infrastructure-as-code)
* [Cloud Foundation Toolkit: Project Factory](https://github.com/terraform-google-modules/terraform-google-project-factory)
* [Cloud Foundation Toolkit: Network module](https://github.com/terraform-google-modules/terraform-google-network)
* [CICD Pipeline Mock-up](https://keybank.atlassian.net/wiki/spaces/CNPM/pages/379945638/CI+CD+Infrastructure+Pipeline)
* [KeyBank: Terraform Project Placement](https://keybank.atlassian.net/wiki/spaces/CNPM/pages/358416886/Terraform+project+placement+diagram)
* [KeyBank: Terraform State Files Organization](https://keybank.atlassian.net/wiki/spaces/CNPM/pages/358286212/Terraform+consolidated+state+file+folder+architecture+diagram)

