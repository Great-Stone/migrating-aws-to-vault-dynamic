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

resource "aws_iam_user" "vault" {
  name = "vault-root"
  path = "/"
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

resource "aws_iam_user_policy" "vault" {
  name = "vault-root"
  user = aws_iam_user.vault.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:AttachUserPolicy",
        "iam:CreateAccessKey",
        "iam:CreateUser",
        "iam:DeleteAccessKey",
        "iam:DeleteUser",
        "iam:DeleteUserPolicy",
        "iam:DetachUserPolicy",
        "iam:GetUser",
        "iam:ListAccessKeys",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupsForUser",
        "iam:ListUserPolicies",
        "iam:PutUserPolicy",
        "iam:AddUserToGroup",
        "iam:RemoveUserFromGroup"
      ],
      "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/vault-*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:AddUserToGroup",
        "iam:RemoveUserFromGroup",
        "iam:GetGroup"
      ],
      "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/*"]
    }
  ]
}
EOF
}

provider "vault" {
  address   = var.vault_addr
  namespace = var.vault_namespace
}

resource "vault_aws_secret_backend" "aws" {
  access_key                = aws_iam_access_key.vault.id
  secret_key                = aws_iam_access_key.vault.secret
  region                    = "ap-northeast-2"
  path                      = "aws-${data.aws_caller_identity.current.user_id}"
  default_lease_ttl_seconds = 90000 # 25h
  max_lease_ttl_seconds     = 90000 # 25h

  provisioner "local-exec" {
    when = destroy
    command = "vault lease revoke -prefix ${self.path}"
  }
}

resource "vault_aws_secret_backend_role" "role" {
  for_each        = local.policies_data
  backend         = vault_aws_secret_backend.aws.path
  name            = each.key
  credential_type = "iam_user"

  policy_arns     = each.value.attated_policies
  iam_groups      = each.value.groups
  policy_document = jsonencode(each.value.user_policies)
}

resource "vault_policy" "aws" {
  for_each = local.policies_data
  name     = "aws-${data.aws_caller_identity.current.user_id}-role-${each.key}"

  policy = <<EOT
path "${vault_aws_secret_backend.aws.path}/creds/${vault_aws_secret_backend_role.role[each.key].name}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_auth_backend" "approle_aws" {
  type = "approle"
  path = "approle-aws"
}

resource "vault_approle_auth_backend_role" "aws" {
  for_each       = local.policies_data
  backend        = vault_auth_backend.approle_aws.path
  role_name      = each.key
  token_policies = ["${vault_policy.aws[each.key].name}"]
}

//////////
// DEBUG
locals {
  users = keys(local.policies_data)
}

resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = vault_auth_backend.approle_aws.path
  role_name = vault_approle_auth_backend_role.aws[one(local.users)].role_name
}

resource "vault_approle_auth_backend_login" "login" {
  backend   = vault_auth_backend.approle_aws.path
  role_id   = vault_approle_auth_backend_role.aws[one(local.users)].role_id
  secret_id = vault_approle_auth_backend_role_secret_id.id.secret_id
}

// output "user_id" {
//   value = data.aws_caller_identity.current
// }

output "vault_approle_auth_backend_login" {
  value = "VAULT_ADDR=${var.vault_addr} VAULT_NAMESPACE=${var.vault_namespace} VAULT_TOKEN=${vault_approle_auth_backend_login.login.client_token} vault read ${vault_aws_secret_backend.aws.path}/creds/${vault_aws_secret_backend_role.role[one(local.users)].name}"
}