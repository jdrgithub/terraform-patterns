# Verify VPC peering

This guide covers the current lab: two VPCs in the same AWS account and `us-east-1`, created by `module.vpc_a` and `module.vpc_b[0]`.

| Item | Expected value |
|---|---|
| VPC A CIDR | `10.0.0.0/16` |
| VPC B CIDR | `10.1.0.0/16` |
| Peering resource | `aws_vpc_peering_connection.peer[0]` |
| Enable switch | `enable_peering = true` |
| Acceptance | `auto_accept = true` |

An **Active** connection confirms acceptance. It does not create routes or prove that packets can cross it. Console and CLI checks inspect configuration; the EC2 test checks actual traffic.

## 1. Confirm the Terraform deployment

Run from the root directory, `terraform-patterns/other/envs/dev`.

If B and peering have not been deployed, set `enable_peering = true` in `terraform.tfvars`, then run:

```bash
terraform plan
terraform apply
```

Review the plan before approving it. B must receive its own public and private subnet lists within `10.1.0.0/16`.

Inspect the deployed connection and VPCs:

```bash
terraform state show 'aws_vpc_peering_connection.peer[0]'
terraform state show 'module.vpc_a.aws_vpc.main'
terraform state show 'module.vpc_b[0].aws_vpc.main'
```

Record the connection ID (`pcx-...`) and both VPC IDs (`vpc-...`). Use the current IDs, not IDs from a previous deployment.

## 2. AWS console checks

### 2.1 Connection status

1. Select **N. Virginia / us-east-1** in the console region selector.
2. Open **VPC → Peering connections**.
3. Select the connection matching the recorded `pcx-...` ID.
4. Confirm **Status = Active**.
5. Confirm the requester is VPC A and the accepter is VPC B, with the expected CIDRs and account.

### 2.2 Routes in both directions

Open **VPC → Route tables**. Select each table by its VPC ID and Name tag, then open **Routes**.

For this lab, if both public and private subnets should communicate across peering, verify all four tables:

| Route table | Destination | Target | Status |
|---|---|---|---|
| A public | `10.1.0.0/16` | Recorded `pcx-...` ID | Active |
| A private | `10.1.0.0/16` | Same `pcx-...` ID | Active |
| B public | `10.0.0.0/16` | Same `pcx-...` ID | Active |
| B private | `10.0.0.0/16` | Same `pcx-...` ID | Active |

The local route and existing default internet/NAT route remain. The more specific peer CIDR route directs peer traffic to peering.

**If a route is missing, the peering resource has not added it automatically.** Add the required routes in Terraform and apply before testing traffic. Each standalone `aws_route` uses the relevant `route_table_id`, the other VPC's `destination_cidr_block`, and `vpc_peering_connection_id`. Avoid mixing standalone routes and inline `route` blocks for the same table.

### 2.3 Subnet associations

1. Open **VPC → Subnets**.
2. Select a subnet and open **Route table**.
3. Confirm the associated table is the intended public or private table.
4. Confirm that table contains the peer route from the preceding table.
5. Repeat for every subnet intended to use peering.

A route in an unused table has no effect on the subnet. A subnet without an explicit association uses its VPC's main route table.

### 2.4 Network ACLs

On each subnet, open **Network ACL** and inspect inbound and outbound rules.

For an unmodified default NACL, rule `100` allows all traffic in each direction, followed by the final `*` deny rule. If using custom rules, confirm both request and return traffic are allowed. NACLs are stateless; TCP return traffic typically requires ephemeral destination ports.

AWS documents the required two-way routes in [Update route tables for VPC peering](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html).

## 3. AWS CLI checks without EC2

Run these commands in WSL/Bash. Replace the placeholder IDs before running them. The commands in this section are read-only.

### 3.1 Set the profile, region, and resource IDs

```bash
export AWS_PROFILE=free-tier
export AWS_REGION=us-east-1
export AWS_PAGER=''

VPC_A_ID='vpc-REPLACE_WITH_A'
VPC_B_ID='vpc-REPLACE_WITH_B'
PEERING_ID='pcx-REPLACE_WITH_CONNECTION'
```

Use the actual configured profile if it differs from `free-tier`. These environment settings apply to the current shell.

Confirm authentication and account:

```bash
aws sts get-caller-identity --output table
```

If this fails, resolve AWS authentication before interpreting any networking results.

### 3.2 Check VPC CIDRs

```bash
aws ec2 describe-vpcs \
  --vpc-ids "$VPC_A_ID" "$VPC_B_ID" \
  --query 'Vpcs[].{VPC:VpcId,CIDR:CidrBlock,State:State}' \
  --output table
```

Expect the two CIDRs listed at the top of this guide and `available` state.

### 3.3 Check the peering connection

```bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids "$PEERING_ID" \
  --query 'VpcPeeringConnections[].{Peering:VpcPeeringConnectionId,Status:Status.Code,Message:Status.Message,Requester:RequesterVpcInfo.VpcId,Accepter:AccepterVpcInfo.VpcId}' \
  --output table
```

Expect `active` and the correct requester/accepter IDs. Other states, such as `pending-acceptance`, `failed`, or `deleted`, do not pass this check. See the [AWS CLI connection reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-vpc-peering-connections.html).

### 3.4 List routes and subnet associations

```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_A_ID,$VPC_B_ID" \
  --query 'RouteTables[].{Table:RouteTableId,VPC:VpcId,Associations:Associations[].{Subnet:SubnetId,Main:Main},Routes:Routes[].{Destination:DestinationCidrBlock,Peering:VpcPeeringConnectionId,Gateway:GatewayId,NAT:NatGatewayId,State:State}}' \
  --output json
```

Find the four public/private tables and compare their peer destinations and targets with section 2.2. The VPC's automatically created main table may also appear; it need not have a peer route if no relevant subnet uses it.

List subnets to match their IDs to names and CIDRs:

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_A_ID,$VPC_B_ID" \
  --query 'Subnets[].{Subnet:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table
```

A missing explicit subnet association means the main table applies. In the route-table response, identify that table by `Main: true`. See the [AWS CLI route-table reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-route-tables.html).

### 3.5 Inspect NACLs

```bash
aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_A_ID,$VPC_B_ID" \
  --query 'NetworkAcls[].{ACL:NetworkAclId,VPC:VpcId,Default:IsDefault,Subnets:Associations[].SubnetId,Rules:Entries}' \
  --output json
```

Match each relevant subnet to its ACL. `Egress: false` means inbound; `Egress: true` means outbound. Inspect rule order, action, protocol, CIDR, and ports.

These checks confirm configuration only. A laptop's ordinary internet connection cannot directly ping these private VPC addresses.

## 4. Actual traffic test using two temporary EC2 instances

This test places one instance in a public subnet in each VPC. SSH uses their public IPs for administration; **the peering test uses their private IPs**. It verifies the selected public subnet pair, not the private subnet tables or every AZ.

### 4.1 Launch test A

In **EC2 → Instances → Launch instances**, set:

| Setting | Value |
|---|---|
| Name | `peering-test-a` |
| AMI | Ubuntu Server 24.04 LTS, x86_64 |
| Instance type | `t3.micro` |
| Key pair | An existing accessible key, or a new downloaded `.pem` key |
| VPC | VPC A's recorded ID |
| Subnet | A public subnet with the verified peering route |
| Auto-assign public IP | Enable |
| Security group | Create `peering-test-a-sg` in VPC A |
| Inbound SSH | TCP 22 from **My IP** only |
| Outbound | Keep default allow-all for this temporary test |

Under **Network settings → Edit**, explicitly select the VPC and subnet. The selected public subnet must have `0.0.0.0/0 → internet gateway` for the SSH session.

Launch the instance. Wait for it to be running and its status checks to pass. Record its public and private IPv4 addresses from the instance Details tab.

### 4.2 Launch test B

Repeat with name `peering-test-b`, VPC B, a public subnet in B, and a separate security group `peering-test-b-sg` in VPC B. Enable its public IP and allow SSH from **My IP**. The same key pair can be used for both instances.

These temporary instances, storage, and public IPv4 addresses may incur charges. Terminate them after testing.

### 4.3 Allow the private-IP test traffic

In **EC2 → Security Groups**, edit inbound rules:

| Security group | Rule | Source |
|---|---|---|
| `peering-test-a-sg` | All ICMP – IPv4 | B's private IP with `/32` |
| `peering-test-b-sg` | All ICMP – IPv4 | A's private IP with `/32` |
| `peering-test-b-sg` | Custom TCP, port `8000` | A's private IP with `/32` |

For example, if A's actual private IP is `10.0.1.25`, the source on B is `10.0.1.25/32`. Use actual assigned addresses. Retain the SSH rules for administration.

### 4.4 Connect to both instances

In WSL, store the key under the Linux home directory and restrict its permissions. Replace the filename and addresses:

```bash
chmod 400 ~/.ssh/peering-lab.pem
ssh -i ~/.ssh/peering-lab.pem ubuntu@A_PUBLIC_IP
```

In a second terminal:

```bash
ssh -i ~/.ssh/peering-lab.pem ubuntu@B_PUBLIC_IP
```

Use `ubuntu` for the chosen Ubuntu AMI. Compare the SSH host fingerprint with the instance's system-log fingerprint before accepting a new host key. AWS describes this in [Connect to a Linux instance using SSH](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html).

### 4.5 Ping across the peering connection

Inside A's SSH session:

```bash
ping -c 4 B_PRIVATE_IP
```

Inside B's SSH session:

```bash
ping -c 4 A_PRIVATE_IP
```

Replace the placeholders with the recorded private addresses. Expect replies and ideally `0% packet loss`. This verifies ICMP connectivity and return routing. Pinging a public IP does not verify peering.

### 4.6 Test TCP and HTTP

Inside B's SSH session:

```bash
mkdir -p /tmp/peering-test
printf 'Hello from VPC B\n' > /tmp/peering-test/index.html
python3 -m http.server 8000 --bind 0.0.0.0 --directory /tmp/peering-test
```

Leave the server running. If `python3` is unavailable, install it with `sudo apt-get update` followed by `sudo apt-get install -y python3`.

Inside A's SSH session:

```bash
curl --connect-timeout 5 --max-time 10 http://B_PRIVATE_IP:8000/
```

Expect:

```text
Hello from VPC B
```

B's terminal should log the request from A's private IP. That confirms TCP communication over the private path. If `curl` is missing on A, install it with `sudo apt-get update` followed by `sudo apt-get install -y curl`.

### 4.7 Testing private subnets as well

To verify private subnet routing with real traffic, repeat the test with instances in the private subnets. Reach them through an existing working Session Manager setup or use the public instances above as SSH jump hosts.

For a jump-host test, launch private Ubuntu instances using the same key pair and no public IP. Allow TCP 22 on each private instance from its own VPC's public jump host private IP (`/32`). Allow the cross-VPC ICMP/8000 rules between the private test instances as in section 4.3.

From WSL, the following reaches private A through public A without copying the private key onto the jump host:

```bash
ssh -i ~/.ssh/peering-lab.pem \
  -o 'ProxyCommand=ssh -i ~/.ssh/peering-lab.pem -W %h:%p ubuntu@A_PUBLIC_IP' \
  ubuntu@A_PRIVATE_TEST_IP
```

Use B's public/private test addresses in another terminal. Repeat ping and HTTP with the private test instances' addresses. Their subnets' private route tables must contain the two-way peer routes. Repeat for other subnet pairs if all subnet paths need testing.

## 5. Troubleshooting

| Result | Check next |
|---|---|
| Connection Active, no traffic | Peer routes in both actual subnet route tables |
| Route shows Blackhole | Target connection ID and connection status |
| SSH to public IP times out | Public IP, IGW route, SSH source IP rule, NACL, instance status |
| Ping fails but HTTP succeeds | ICMP rules or host firewall; TCP peering works |
| Ping succeeds but HTTP times out | TCP 8000 rule, NACL ports, host firewall |
| HTTP says Connection refused | Server running and listening on `0.0.0.0:8000` |
| Public subnet test succeeds, private test fails | Private subnet associations, routes, and rules |
| CLI credential error | Profile/login; this is separate from peering |

For TCP troubleshooting on B:

```bash
ss -lnt | grep ':8000'
sudo ufw status
```

The first command should show a listener. Inspect a configured host firewall rather than disabling it indiscriminately.

## 6. Cleanup

1. Stop the Python server with **Ctrl+C**.
2. In **EC2 → Instances**, select only the temporary test instances and choose **Instance state → Terminate (delete) instance**.
3. Confirm the test instances terminate. Check for leftover test volumes if delete-on-termination was disabled.
4. Delete the temporary test security groups after their network interfaces have been removed. Remove any references between test groups first if applicable.
5. Delete a test-only key pair and its local key file if no longer needed.

These console-created test instances are outside Terraform state; `terraform destroy` will not manage them and they can block VPC deletion.

Keep the VPCs if continuing the lab. For a complete Terraform lab teardown, run from the root directory and review the proposed destruction:

```bash
terraform destroy
```

## Completion checklist

- [ ] Correct VPC IDs and non-overlapping CIDRs
- [ ] Peering status Active
- [ ] Peer routes present and Active in every intended route table
- [ ] Subnets associated with the correct tables
- [ ] NACLs allow request and return traffic
- [ ] Test security groups allow the selected protocols
- [ ] Private-IP ping works between test endpoints
- [ ] Private-IP HTTP response reads `Hello from VPC B`
- [ ] Temporary test resources removed
