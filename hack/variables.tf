variable "resource_group_name" {
  description = "Name of the Resource Group"
}

variable "storage_account_name" {
  description = "Name of the Storage Account"
}

variable "argocd_namespace" {
  description = "Namespace of the argocd instance"
}

variable "kubernetes_namespace" {
  description = "Namespace to deploy to"
}

variable "vault_token" {
  description = "Vault token"
}

variable "location" {
  description = "Azure Location"
  default = "canadacentral"
}
