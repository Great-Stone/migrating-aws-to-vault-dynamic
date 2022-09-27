terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.32.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.8.2"
    }
  }
}

provider "aws" {

}

data "aws_caller_identity" "current" {}

locals {
  policies_data = jsondecode(file("${path.module}/policies_data.json"))
}

provider "vault" {
  address   = var.vault_addr
  namespace = "admin"
}

resource "vault_aws_secret_backend" "aws" {
  // access_key = "AKIA....."
  // secret_key = "AWS secret key"
  region                    = "ap-northeast-2"
  path                      = "aws-${data.aws_caller_identity.current.user_id}"
  default_lease_ttl_seconds = 90000 # 25h
  max_lease_ttl_seconds     = 90000 # 25h
}

resource "vault_aws_secret_backend_role" "role" {
  depends_on = [
    null_resource.policies_data
  ]
  for_each        = local.policies_data
  backend         = vault_aws_secret_backend.aws.path
  name            = each.key
  credential_type = "iam_user"

  policy_arns     = each.value.attated_policies
  iam_groups      = each.value.groups
  policy_document = jsonencode(local.policies_data["hahohh"].user_policies)
}

// output "user_id" {
//   value = data.aws_caller_identity.current.user_id
// }

// output "policies_data" {
//   value = local.policies_data
// }
