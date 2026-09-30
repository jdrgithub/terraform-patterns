resource "vault_mount" "kv" {
  path        = "terraform-kv"
  type        = "kv-v2"
  description = "KV secrets engine managed by Terraform"
}

ephemeral "vault_kv_secret_v2" "demo" {
  mount = vault_mount.kv.path
  name  = "demo-app"
}

resource "vault_kv_secret_v2" "copy" {
  mount = vault_mount.kv.path
  name = "demo-copy"

  data_json_wo = jsonencode({
    api_key = ephemeral.vault_kv_secret_v2.demo.data["api_key"]
  })

  data_json_wo_version = 1
}