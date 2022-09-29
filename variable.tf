variable "vault_addr" {
  type        = string
  description = "Vault Address"
}

variable "vault_namespace" {
  type = string
  description = "Vault Namespace. Available only for Vault Enterprise & HCP Vault"
  default = ""
}