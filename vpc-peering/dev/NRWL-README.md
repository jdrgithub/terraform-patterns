# AWS VPC networking and peering lab

Terraform networking project based on the [Nrwl AWS networking interview exercise](https://github.com/nrwl/infrastructure-interview/blob/main/modules/aws-networking/README.md).

The project uses a reusable VPC child module to create two independent networks and connect them with VPC peering. The root module supplies each VPC's configuration and manages the connection between them.

This README describes the same-account, same-region design discussed during development. It is based on the shared configuration snippets, not a review of the complete repository. Examples below use separate A/B subnet variable names; align those names with the final root configuration. Peering routes must be implemented before the connectivity checks can pass.

## Architecture

Both VPCs are deployed in `us-east-1`.

| Component | VPC A | VPC B |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Public subnets | Configurable list within A's CIDR | Configurable list within B's CIDR |
| Private subnets | Configurable list within A's CIDR | Configurable list within B's CIDR |
| Internet gateway | One | One |
| Public NAT gateway | One, in the first public subnet | One, in the first public subnet |
| Elastic IP | One for the NAT gateway | One for the NAT gateway |
| Route tables | One public, one private | One public, one private |
| Peering | One shared connection between A and B | Same connection |

The number of subnets is controlled by the input lists. The recent development example uses two public and two private subnets per VPC; expand the lists if the exercise deliverable requires three Availability Zones.

Public route tables send default internet traffic to the internet gateway. Private route tables send default internet traffic to the NAT gateway. Each subnet is explicitly associated with the appropriate table.

Traffic between VPCs uses their private IP addresses and the peering connection. The VPC CIDRs must not overlap. Public and private subnets must both fit within their own VPC's CIDR and must not overlap each other.

### Peering routes

For all public and private subnets to participate, the following additional routes are required:

| Route table | Destination | Target |
|---|---|---|
| A public | `10.1.0.0/16` | Peering connection |
| A private | `10.1.0.0/16` | Peering connection |
| B public | `10.0.0.0/16` | Peering connection |
| B private | `10.0.0.0/16` | Peering connection |

These routes supplement the automatic local routes and existing internet/NAT routes. Creating a peering connection does not create these routes automatically. [AWS peering routing documentation](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html)

## Project organization

Paths are relative to `terraform-patterns/other/`.

| Location | Responsibility |
|---|---|
| `envs/dev/main.tf` | Calls the VPC module and creates optional peering |
| `envs/dev/providers.tf` | Terraform/provider requirements and AWS provider configuration |
| `envs/dev/variables.tf` | Root input declarations |
| `envs/dev/terraform.tfvars` | Actual CIDRs, subnet lists, names, and enable switch |
| `envs/dev/outputs.tf` | Optional root outputs for convenient inspection |
| `modules/vpc-nrwl/main.tf` | Resources for one VPC and its networking |
| `modules/vpc-nrwl/variables.tf` | Reusable child-module input declarations |
| `modules/vpc-nrwl/outputs.tf` | Values exposed to the root, including `vpc_id` |

File names organize the configuration; Terraform reads the `.tf` files in each module directory together.

The root owns provider configuration and state. The child declares its provider requirements but contains no `provider "aws"` configuration block. This permits the root to use `count` on the module call.

## Requirements

- Terraform satisfying the configured constraint, currently `~> 1.16.0` in the shared example.
- HashiCorp AWS provider satisfying the configured constraint, currently `~> 6.65.0`.
- AWS credentials authorized to manage the lab's VPC networking resources.
- AWS CLI for account checks and command-line verification.

The AWS provider version is selected during `terraform init` and recorded in the root's `.terraform.lock.hcl`.

## Inputs

The child module accepts the following inputs in the shared design:

| Input | Type | Purpose |
|---|---|---|
| `vpc_cidr` | `string` | CIDR for this VPC |
| `name_postfix` | `string` | Distinguishes AWS names for A and B |
| `public_subnets` | List of objects | Public subnet names, CIDRs, and AZs |
| `private_subnets` | List of objects | Private subnet names, CIDRs, and AZs |

Both subnet inputs use this type:

```hcl
list(object({
  name = string
  cidr = string
  az   = string
}))
```

Subnet resources use `for_each` keyed by `name`. Names must be unique within each input list and should remain stable to avoid changing Terraform resource addresses.

The NAT gateway uses the subnet selected by:

```hcl
aws_subnet.public[var.public_subnets[0].name].id
```

At least one public subnet is required. Reordering the list can change NAT placement.

### Separate values for A and B

The child input names remain identical in both calls. The root passes different values to each instance. For example:

```hcl
# Inside module "vpc_a"
public_subnets  = var.public_subnets_a
private_subnets = var.private_subnets_a

# Inside module "vpc_b"
public_subnets  = var.public_subnets_b
private_subnets = var.private_subnets_b
```

Declare those four root variables and assign their values in the root's `terraform.tfvars`. The child continues to declare only `public_subnets` and `private_subnets`.

Example CIDR allocation:

| Subnet | A | B |
|---|---|---|
| Public, AZ a | `10.0.1.0/24` | `10.1.1.0/24` |
| Public, AZ b | `10.0.2.0/24` | `10.1.2.0/24` |
| Private, AZ a | `10.0.3.0/24` | `10.1.3.0/24` |
| Private, AZ b | `10.0.4.0/24` | `10.1.4.0/24` |

## Optional second VPC

The root's `enable_peering` boolean controls VPC B and the peering connection together:

| Value | Desired deployment |
|---|---|
| `false` | VPC A only |
| `true` | VPC A, VPC B, and peering |

Both B and the peering resource use:

```hcl
count = var.enable_peering ? 1 : 0
```

The root's connection references are:

```hcl
vpc_id      = module.vpc_a.vpc_id
peer_vpc_id = module.vpc_b[0].vpc_id
```

The `[0]` selects the module instance created by `count`. The child exposes its VPC ID with:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

Because both VPCs are in the same account and region, the connection uses `auto_accept = true`. A separate accepter resource is unnecessary for this design.

Peering routes must use the same enable condition. If managed in the root, the child must also expose its public and private route-table IDs.

Changing `enable_peering` from `true` to `false` after deployment plans deletion of B and peering; it does not merely pause them.

## Provider configuration

A single default provider is sufficient:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Both module calls inherit it. If an aliased provider is used instead, pass it explicitly in each module call and select it for root AWS resources as needed.

## Deploy

Run from the repository's `other/envs/dev` directory.

Configure the shell to use the intended AWS profile. Replace `free-tier` if the profile has a different name:

```bash
export AWS_PROFILE=free-tier
export AWS_REGION=us-east-1
aws sts get-caller-identity
```

Confirm the returned account, then initialize and validate:

```bash
terraform init
terraform fmt -recursive ../../modules/vpc-nrwl
terraform fmt
terraform validate
terraform plan
```

Review the planned resources and CIDRs. Apply the configuration:

```bash
terraform apply
```

Terraform requests confirmation before making changes. NAT gateway provisioning and deletion can take several minutes.

## State and source control

This lab initially uses local state. Run Terraform from the root directory so both module instances and peering are managed in the same state.

- Commit Terraform configuration and the root's `.terraform.lock.hcl`.
- Exclude `.terraform/`, `*.tfstate`, `*.tfstate.*`, and saved plan files from version control.
- Keep credentials and private keys out of configuration and Git.
- Preserve state while resources exist. Deleting state does not delete AWS resources.

## Verification

1. Confirm the peering connection is Active and references the correct VPC IDs.
2. Confirm the peer routes and subnet associations on both sides.
3. Inspect NACLs and test-instance security groups.
4. Test between private IPs using temporary EC2 instances for actual connectivity verification.

The existing [verification guide](README.md) contains console navigation, AWS CLI commands, EC2 setup, ping/HTTP tests, troubleshooting, and test-resource cleanup. It is currently named `README.md`; when installing this document as the repository README, rename the verification guide to `VERIFICATION.md` and update this link accordingly.

An Active connection alone does not prove end-to-end connectivity.

## Design limitations

- One NAT gateway per VPC is a lab simplification. Private subnets in other AZs depend on that NAT gateway's AZ.
- Default NACLs are used unless custom ACL resources are added. Peering does not grant security-group access automatically.
- EC2 instances are test fixtures, not part of the core networking module.
- This version targets a single region and account; cross-region or cross-account peering requires additional provider/acceptance configuration.
- Subnet count and the final module interface should be checked against the original exercise before submission. This document does not certify completion of every exercise requirement.

## Cleanup

Terminate any manually created test instances before removing their VPCs. Terraform does not manage console-created test instances, and they can block network deletion.

From the root directory:

```bash
terraform plan -destroy
terraform destroy
terraform state list
```

After successful teardown, the state list should contain no tracked resources. Terraform retains the local state file. NAT gateways and public IPv4 addresses can incur charges while provisioned, so complete the teardown when the lab is no longer needed.
