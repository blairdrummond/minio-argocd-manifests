"auto_auth" = {
  "method" = {
    "config" = {
      "role" = "boathouse"
    }
    "type" = "kubernetes"
    "mount_path" = "auth/aaw-prod-cc-00"
  }
}

"exit_after_auth" = false
"pid_file" = "/home/vault/.pid"

cache {
  "use_auto_auth_token" = "force"
}

listener "tcp" {
  address = "127.0.0.1:8100"
  "tls_disable" = true
}

"vault" = {
  "address" = "http://vault.vault-system:8200"
}
