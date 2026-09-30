# Terraform + AWS Secrets Manager Demo

This demo shows how to use Terraform with AWS Secrets Manager and allow an EC2 instance to retrieve a secret using an IAM role.

It demonstrates:

- Creating a Secrets Manager secret with Terraform
- Adding a test secret value
- Seeing why normal secret values can be exposed in Terraform state
- Storing the secret value outside Terraform
- Giving EC2 permission to read the secret
- Retrieving the secret from EC2 using its IAM role

---

## 1. Prerequisites

Verify Terraform:

```bash
terraform version
```

Verify the AWS CLI:

```bash
aws --version
```

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

---

## 2. Create the Secrets Manager Secret

Create a small child module:

```text
modules/
└── secrets/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### `main.tf`

```hcl
resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description

  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}
```

### `variables.tf`

```hcl
variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "recovery_window_in_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### `outputs.tf`

```hcl
output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}
```

---

## 3. Call the Secrets Module

From the root module:

```hcl
module "secret" {
  source = "../modules/secrets"

  name        = "dev/demo-app/api-key"
  description = "API key used by the demo application"

  tags = {
    Environment = "dev"
  }
}
```

Run:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Verify:

```bash
aws secretsmanager describe-secret \
  --secret-id dev/demo-app/api-key
```

The secret container now exists.

---

## 4. Add a Test Secret Value with Terraform

Temporarily add a secret version:

```hcl
resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = "demo-api-key-12345"
}
```

Apply:

```bash
terraform apply
```

Read the value:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/demo-app/api-key \
  --query SecretString \
  --output text
```

Expected result:

```text
demo-api-key-12345
```

---

## 5. Inspect Terraform State

Check whether the secret value was stored in state:

```bash
terraform state pull | grep demo-api-key-12345
```

The value appears in Terraform state.

This demonstrates an important distinction:

```text
sensitive != absent from state
```

Terraform can hide sensitive values from normal command output while still storing them in state.

---

## 6. Store the Secret Value Outside Terraform

Remove the `aws_secretsmanager_secret_version` resource from the Terraform configuration.

Keep the `aws_secretsmanager_secret` resource so Terraform continues managing the secret itself.

Store the actual value directly in Secrets Manager:

```bash
aws secretsmanager put-secret-value \
  --secret-id dev/demo-app/api-key \
  --secret-string 'demo-api-key-67890'
```

Verify:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/demo-app/api-key \
  --query SecretString \
  --output text
```

Now:

```text
Terraform
    |
    +---- manages the secret container

Secrets Manager
    |
    +---- stores the actual secret value
```

---

## 7. Give EC2 Permission to Read the Secret

Create an IAM policy that allows the EC2 role to retrieve this particular secret.

```hcl
resource "aws_iam_policy" "secrets_read" {
  name        = "demo-secrets-read"
  description = "Allow EC2 to read the demo application secret"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.secret_arn
      }
    ]
  })
}
```

Add the module input:

```hcl
variable "secret_arn" {
  description = "ARN of the Secrets Manager secret EC2 may read"
  type        = string
}
```

Pass the secret ARN from the root module:

```hcl
module "iam" {
  source = "../modules/iam"

  secret_arn = module.secret.secret_arn
}
```

---

## 8. Attach the Policy to the EC2 Role

```hcl
resource "aws_iam_role_policy_attachment" "secrets_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.secrets_read.arn
}
```

The EC2 role can now call:

```text
secretsmanager:GetSecretValue
```

for this secret.

---

## 9. Attach the IAM Role to EC2

Create an instance profile for the EC2 role:

```hcl
resource "aws_iam_instance_profile" "ec2" {
  name = "demo-ec2-profile"
  role = aws_iam_role.ec2.name
}
```

Expose its name from the IAM module:

```hcl
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}
```

Pass it into the EC2 module:

```hcl
module "ec2" {
  source = "../modules/ec2"

  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids["us-east-1a"]
  sg_cidr   = var.sg_cidr

  instance_profile = module.iam.instance_profile_name
}
```

Inside the EC2 module:

```hcl
variable "instance_profile" {
  type = string
}
```

And on the instance:

```hcl
resource "aws_instance" "web" {
  # ...

  iam_instance_profile = var.instance_profile
}
```

Apply:

```bash
terraform apply
```

---

## 10. Retrieve the Secret from EC2

Connect to the EC2 instance.

Verify its AWS identity:

```bash
aws sts get-caller-identity
```

Then retrieve the secret:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/demo-app/api-key \
  --query SecretString \
  --output text
```

Expected:

```text
demo-api-key-67890
```

The complete flow is:

```text
EC2
 |
 | IAM instance profile
 v
IAM role
 |
 | secretsmanager:GetSecretValue
 v
Secrets Manager
 |
 v
Secret returned at runtime
```

No long-lived AWS access keys need to be stored on the EC2 instance.

---

## 11. Cleanup

Destroy the Terraform-managed infrastructure:

```bash
terraform destroy
```

If you want to immediately delete a disposable Secrets Manager secret rather than wait for its recovery period:

```bash
aws secretsmanager delete-secret \
  --secret-id dev/demo-app/api-key \
  --force-delete-without-recovery
```

Use `--force-delete-without-recovery` only for disposable test secrets.

---

# Useful Secrets Manager Commands

List secrets:

```bash
aws secretsmanager list-secrets
```

Describe a secret:

```bash
aws secretsmanager describe-secret \
  --secret-id dev/demo-app/api-key
```

Read a secret:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/demo-app/api-key
```

Read only the secret string:

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/demo-app/api-key \
  --query SecretString \
  --output text
```

Store a new value:

```bash
aws secretsmanager put-secret-value \
  --secret-id dev/demo-app/api-key \
  --secret-string 'new-secret-value'
```

List secret versions:

```bash
aws secretsmanager list-secret-version-ids \
  --secret-id dev/demo-app/api-key
```

List secrets including ones scheduled for deletion:

```bash
aws secretsmanager list-secrets \
  --include-planned-deletion
```

Restore a secret scheduled for deletion:

```bash
aws secretsmanager restore-secret \
  --secret-id dev/demo-app/api-key
```

Schedule deletion:

```bash
aws secretsmanager delete-secret \
  --secret-id dev/demo-app/api-key \
  --recovery-window-in-days 7
```

---

# Key Takeaways

- Terraform can manage the Secrets Manager secret without managing the actual secret value.
- A normal Terraform-managed secret value can be stored in Terraform state.
- `sensitive` does not mean the value is absent from state.
- Applications can retrieve secrets from Secrets Manager at runtime instead.
- EC2 should use an IAM role and instance profile rather than stored AWS access keys.
- `secretsmanager:GetSecretValue` provides the permission needed to retrieve the secret.
- IAM permissions can be restricted to the ARN of the specific secret.
- Terraform state should itself be treated as sensitive data.