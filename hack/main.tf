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

  depends_on = [azurerm_resource_group.rg]
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

  depends_on = [kubernetes_namespace.minio_namespace]
}


resource "random_password" "minio_access_key" {
  length           = 24
  special          = false
}

resource "random_password" "minio_secret_key" {
  length           = 36
  special          = false
}

resource "kubernetes_secret" "minio_secret" {
  metadata {
    name      = "minio-gateway-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    access-key = random_password.minio_access_key.result
    secret-key = random_password.minio_secret_key.result
  }
}

resource "kubectl_manifest" "gateway_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: minio-gateway-root
  namespace: ${var.argocd_namespace}
spec:
  project: default
  destination:
    namespace: ${var.kubernetes_namespace}
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/blairdrummond/minio-argocd-manifests.git
    targetRevision: main
    path: .
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML

  depends_on = [kubernetes_namespace.minio_namespace]
}


# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [kubectl_manifest.gateway_application]
#   create_duration = "45s"
# }
#
#
# # We wait 45s after the creation of the gateway
# # for everything to boot and for a new secret to
# # be created. We wait for the sleep to finish
# # before sourcing the secert.
# data "kubernetes_secret" "minio_secret" {
#   metadata {
#     name      = "minio-gateway"
#     namespace = var.kubernetes_namespace
#   }
#   depends_on = [
#     time_sleep.wait_30_seconds
#   ]
# }

resource "vault_mount" "minio_gateway" {
  path = "minio_gateway"
  type = "vault-plugin-secrets-minio"
}

resource "vault_generic_secret" "minio_standard_config" {
  path = "${vault_mount.minio_gateway.path}/config"

  data_json = <<EOT
{
  "endpoint": "minio-gateway.${var.kubernetes_namespace}:9000",
  "accessKeyId": "${kubernetes_secret.minio_secret.data["access-key"]}",
  "secretAccessKey": "${kubernetes_secret.minio_secret.data["secret-key"]}",
  "useSSL": false
}
EOT
}
