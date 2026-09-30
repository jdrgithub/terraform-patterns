## 1. Install Vault on Ubuntu / WSL

Install the required packages:

```bash
sudo apt update
sudo apt install -y gpg wget
```

Add HashiCorp's signing key:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

Add the HashiCorp repository:

```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

Install Vault:

```bash
sudo apt update
sudo apt install vault
```

Verify:

```bash
vault version
```

## Cleanup

The original `demo-app` secret was deliberately removed from Terraform state during the exercise, so `terraform destroy` will not delete it.

First destroy the resources Terraform still manages:

```bash
terraform destroy
```

Then, if the `terraform-kv` mount still exists, permanently remove the manually retained `demo-app` secret and all of its versions with:

```bash
vault kv metadata delete terraform-kv/demo-app
```

If Terraform destroyed the `terraform-kv` mount, the secrets stored under that mount are destroyed with it, so the separate Vault command is unnecessary.