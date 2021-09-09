terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.11.3"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.4.1"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "2.21.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}


# This is just a local testing instance
provider "vault" {
  address = "http://0.0.0.0:8200"
  token = var.vault_token
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-argoflow"
}

provider "azurerm" {
  features {}
}
