resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "canadacentral"
}


resource "azurerm_storage_account" "gateway" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # See also StorageV2
  account_kind             = "BlobStorage"

  enable_https_traffic_only = true
  allow_blob_public_access  = false
  min_tls_version           = "TLS1_2"

  # Use object versioning instead
  is_hns_enabled           = "false"

  blob_properties {
    versioning_enabled       = "true"
    change_feed_enabled      = "true"
  }
}


resource "kubernetes_namespace" "minio_namespace" {
  metadata {
    name = var.kubernetes_namespace

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# The MinIO Helm chart is expecting this to exist
resource "kubernetes_secret" "blob_storage" {
  metadata {
    name = "azure-blob-storage"
    namespace = var.kubernetes_namespace
  }
  data = {
    storageAccountName = azurerm_storage_account.gateway.name
    storageAccountKey = azurerm_storage_account.gateway.secondary_access_key
  }
}


# resource "kubectl_manifest" "gateway_application" {
#   yaml_body = <<YAML
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: minio-gateway
#   namespace: ${var.argocd_namespace}
# spec:
#   project: default
#   destination:
#     namespace: ${var.kubernetes_namespace}
#     server: https://kubernetes.default.svc
#   source:
#     repoURL: https://github.com/blairdrummond/minio-argocd-manifests.git
#     targetRevision: ${var.helm_chart_version}
#     path: .
#   syncPolicy:
#     automated:
#       prune: true
#       selfHeal: true
# YAML
# }


resource "vault_mount" "minio_gateway" {
  path = "minio_gateway"
  type = "minio"
}


# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [kubectl_manifest.gateway_application]
#   create_duration = "45s"
# }


# # We wait 45s after the creation of the gateway
# # for everything to boot and for a new secret to
# # be created. We wait for the sleep to finish
# # before sourcing the secert.
# data "kubernetes_secret" "minio_secret" {
#   metadata {
#     name      = var.name
#     namespace = var.namespace
#   }
#   depends_on = [
#     time_sleep.wait_30_seconds
#   ]
# }
#
#
# resource "vault_generic_secret" "minio_standard_config" {
#   path = "${vault_mount.minio_standard.path}/config"
#
#   data_json = <<EOT
# {
#   "endpoint": "minio.${var.kubernetes_namespace}:443",
#   "accessKeyId": "${var.minio_standard_access}",
#   "secretAccessKey": "${var.minio_standard_secret}",
#   "useSSL": false
# }
# EOT
# }
