####################
##### REMOTE BACKEND 
####################
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "TonyPulickal"

    workspaces {
      name = "ops-tfe-nonprod"
    }
  }
}

####################
##### DATA 
####################
variable "tfe_token" {}

variable "tfe_hostname" {
  description = "The domain where your TFE is hosted."
  default     = "app.terraform.io"
}

variable "tfe_organization" {
  description = "The TFE organization to apply your changes to."
  default     = "TonyPulickal"
}

provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
  version  = "~> 0.6"
}

data "tfe_workspace_ids" "all" {
  names        = ["*"]
  organization = var.tfe_organization
}

locals {
  workspaces = data.tfe_workspace_ids.all.external_ids # map of names to IDs
}

####################
##### POLICY SETS
####################
resource "tfe_policy_set" "global" {
  name          = "global"
  description   = "Policies that should be enforced on ALL environments."
  organization  = var.tfe_organization
  global        = true

  policy_ids = [
    "${tfe_sentinel_policy.limit-cost-by-workspace-type.id}",
    "${tfe_sentinel_policy.require-all-resources-from-pmr.id}",
  ]
}

resource "tfe_policy_set" "aws-global" {
  name          = "aws-global"
  description   = "Policies enforced in ALL AWS environments"
  organization  = var.tfe_organization

  policy_ids = [
    "${tfe_sentinel_policy.aws-enforce-mandatory-tags.id}",
    "${tfe_sentinel_policy.aws-restrict-ingress-sg-rule-cidr-blocks.id}",
  ]

  workspace_external_ids = [
    "${local.workspaces["demo-aws-vpc"]}",
    "${local.workspaces["demo-aws-compute-dev"]}",
  ]
}

resource "tfe_policy_set" "aws-nonprod-compute" {
  name          = "aws-nonprod-compute"
  description   = "Policies enforced in non-production AWS compute environments"
  organization  = var.tfe_organization

  policy_ids = [
    "${tfe_sentinel_policy.aws-restrict-availability-zones.id}",
    "${tfe_sentinel_policy.aws-restrict-ec2-instance-type.id}",
    "${tfe_sentinel_policy.aws-restrict-db-instance-engines.id}",
  ]

  workspace_external_ids = [
    "${local.workspaces["demo-aws-compute-dev"]}",
  ]
}

resource "tfe_policy_set" "azure-nonprod-compute" {
  name          = "azure-nonprod-compute"
  description   = "Policies enforced in non-production Azure compute environments"
  organization  = var.tfe_organization

  policy_ids = [
    "${tfe_sentinel_policy.azure-restrict-vm-size}",
    "${tfe_sentinel_policy.azure-enforce-mandatory-tags}",  
  ]

  workspace_external_ids = [
    "${local.workspaces["demo-az-compute-dev}",
    "${local.workspaces["demo-az-compute-test}",
  ]
}

####################
##### POLICIES
####################

## Global policies
resource "tfe_sentinel_policy" "limit-cost-by-workspace-type" {
  name          = "limit-cost-by-workspace-type"
  description   = "Cap max potential cost by workspace environment."
  organization  = var.tfe_organization
  policy        = "${file("./cloud-agnostic/limit-cost-by-workspace-type.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

resource "tfe_sentinel_policy" "require-all-resources-from-pmr" {
  name          = "require-all-resources-from-pmr"
  description   = "Enforce that all resources originate from Private Module Registry."
  organization  = var.tfe_organization
  policy        = "${file("./cloud-agnostic/require-all-resources-from-pmr.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

## AWS Global Policies
resource "tfe_sentinel_policy" "aws-enforce-mandatory-tags" {
  name          = "aws-enforce-mandatory-tags"
  description   = "Enforce that all AWS resources have required tags."
  organization  = var.tfe_organization
  policy        = "${file("./aws/enforce-mandatory-tags.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

resource "tfe_sentinel_policy" "aws-restrict-ingress-sg-rule-cidr-blocks" {
  name          = "aws-restrict-ingress-sg-rule-cidr-blocks"
  description   = "Enforce that no AWS resources allow inbound traffic to the internet."
  organization  = var.tfe_organization
  policy        = "${file("./aws/restrict-ingress-sg-rule-cidr-blocks.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

## AWS Compute Policies
resource "tfe_sentinel_policy" "aws-restrict-availability-zones" {
  name          = "aws-restrict-availability-zones"
  description   = "Enforce that all AWS resources are created in approved AZs."
  organization  = var.tfe_organization
  policy        = "${file("./aws/restrict-availability-zones.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

resource "tfe_sentinel_policy" "aws-restrict-ec2-instance-type" {
  name          = "aws-restrict-ec2-instance-type"
  description   = "Enforce that all AWS EC2 instances are approved types." 
  organization  = var.tfe_organization
  policy        = "${file("./aws/restrict-ec2-instance-type.sentinel")}"
  enforce_mode  = "soft-mandatory"
}

resource "tfe_sentinel_policy" "aws-restrict-db-instance-engines" {
  name          = "aws-restrict-db-instance-engines"
  description   = "Enforce that all AWS RDS instances are approved types." 
  organization  = var.tfe_organization
  policy        = "${file("./aws/restrict-db-instance-engines.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

## Azure Compute Policies
resource "tfe_sentinel_policy" "azure-enforce-mandatory-tags" {
  name          = "azure-enforce-mandatory-tags"
  description   = "Enforce that all Azure resources have required tags."
  organization  = var.tfe_organization
  policy        = "${file("./azure/enforce-mandatory-tags.sentinel")}"
  enforce_mode  = "hard-mandatory"
}

resource "tfe_sentinel_policy" "azure-restrict-vm-size" {
  name          = "azure-restrict-vm-size"
  description   = "Enforce that all Azure resources have required tags."
  organization  = var.tfe_organization
  policy        = "${file("./azure/restrict-vm-size.sentinel")}"
  enforce_mode  = "soft-mandatory"
}
