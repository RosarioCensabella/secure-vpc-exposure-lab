# Secure VPC Exposure Lab

## Overview

Secure VPC Exposure Lab is an AWS networking and cloud security portfolio project built with Terraform.

The goal of the project is to demonstrate a controlled exposure model where the only public entry point is an internet-facing Application Load Balancer, while the application EC2 instances remain private, have no public IPv4 address, and accept application traffic only from the ALB security group.

This lab focuses on AWS networking, network segmentation, security group design, subnet routing, stateless Network ACL filtering, and VPC Flow Logs observability.

---

## Business Scenario

NovaRetail Cloud is a fictional B2B SaaS company that provides a private order-management application for e-commerce customers.

The company wants to expose a web application to customers through a public endpoint, but it must avoid exposing backend application servers directly to the internet.

The engineering requirement is clear:

- Customers must access the application through a public endpoint.
- Application servers must remain private.
- Inbound application traffic to EC2 must be allowed only from the load balancer.
- Network traffic must be observable for validation and troubleshooting.
- The infrastructure must be reproducible using Infrastructure as Code.

This project implements that requirement using AWS and Terraform.

---

## Architecture Summary

High-level traffic flow:

```text
Internet Client
    |
    v
Internet Gateway
    |
    v
Public Subnets
    |
    v
Internet-facing Application Load Balancer
    |
    v
Private Application Subnets
    |
    v
Private EC2 Application Instances on TCP 8080
```

The final environment contains:

- One custom VPC.
- Two public subnets across two Availability Zones.
- Two private application subnets across two Availability Zones.
- One internet-facing Application Load Balancer.
- One target group forwarding traffic to private EC2 instances on TCP 8080.
- Two private EC2 application instances.
- Security groups using least-privilege rules.
- Custom Network ACLs for subnet-level stateless filtering.
- VPC Flow Logs delivered to CloudWatch Logs.

---

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon VPC | Custom network boundary for the lab |
| Public Subnets | Host the internet-facing Application Load Balancer |
| Private Subnets | Host the application EC2 instances |
| Internet Gateway | Provides internet access path for public subnet resources |
| Route Tables | Separate public and private routing behavior |
| Application Load Balancer | Only public entry point into the application environment |
| Target Group | Routes ALB traffic to private EC2 instances on TCP 8080 |
| Amazon EC2 | Runs the private application instances |
| Security Groups | Enforce stateful least-privilege access control |
| Network ACLs | Demonstrate subnet-level stateless traffic filtering |
| CloudWatch Logs | Destination for VPC Flow Logs |
| VPC Flow Logs | Network-level visibility for accepted and rejected traffic |
| IAM | Dedicated role for VPC Flow Logs delivery |

---

## Security Design

The lab is designed around a simple exposure principle:

> The Application Load Balancer is public. The application instances are private.

### Public Access

The ALB security group allows inbound HTTP traffic:

```text
TCP 80 from 0.0.0.0/0
```

This is the only public inbound access path into the application environment.

### ALB to Application Traffic

The ALB security group allows outbound traffic only to the application security group on TCP 8080:

```text
ALB Security Group -> Application Security Group
TCP 8080
```

### Application Instance Access

The application security group allows inbound traffic only from the ALB security group:

```text
Application Security Group inbound:
TCP 8080 from ALB Security Group
```

The application security group does not allow:

```text
TCP 8080 from 0.0.0.0/0
TCP 22 from 0.0.0.0/0
TCP 3389 from any public source
```

The application security group also has no broad outbound internet rule in the final configuration.

---

## Network Exposure Model

| Component | Exposure | Reason |
|---|---|---|
| Application Load Balancer | Public | It is the only internet-facing application entry point |
| EC2 application instances | Private | They run in private subnets and have no public IPv4 address |
| Application port 8080 | Private behind ALB | Only the ALB security group can reach the application security group |
| SSH | Not exposed | No inbound SSH rule is created |
| RDP | Not exposed | No inbound RDP rule is created |
| VPC Flow Logs | Internal observability | Used to validate accepted and rejected network flows |

---

## Terraform Implementation

The infrastructure is deployed with Terraform.

Main Terraform files:

```text
terraform/
|-- providers.tf
|-- variables.tf
|-- locals.tf
|-- main.tf
|-- vpc.tf
|-- subnets.tf
|-- routes.tf
|-- security-groups.tf
|-- nacl.tf
|-- alb.tf
|-- ec2.tf
|-- flow-logs.tf
|-- iam.tf
`-- outputs.tf
```

The application bootstrap script is stored in:

```text
app/user-data.sh
```

The EC2 application uses a minimal local Python HTTP server started through user data. It does not require external package downloads during boot.

---

## Application Behavior

The private EC2 instances run a simple HTTP application on TCP 8080.

Expected responses:

| Endpoint | Expected Response |
|---|---|
| `/` | `Secure VPC Exposure Lab - Private Application Instance` |
| `/health` | `OK` |

The ALB exposes the application publicly on HTTP port 80 and forwards requests to the private instances on port 8080.

---

## Validation Results

The Phase 1 environment was functionally validated.

### ALB Application Test

```powershell
curl.exe http://<alb_dns_name>/
curl.exe http://<alb_dns_name>/health
```

Expected result:

```text
Secure VPC Exposure Lab - Private Application Instance
OK
```

Evidence:

```text
evidence/screenshots/power-shell/17-functional-curl-tests-cli.png
```

---

### Target Group Health

Both EC2 instances were registered in the target group and reported as healthy.

Evidence:

```text
evidence/screenshots/power-shell/09-target-health-cli.png
evidence/screenshots/aws-console/17-target-group-healthy-targets.png
```

---

### Private EC2 Exposure Validation

The application EC2 instances were confirmed to have private IPv4 addresses and no public IPv4 address.

Evidence:

```text
evidence/screenshots/power-shell/10-ec2-private-instances-cli.png
evidence/screenshots/aws-console/19-ec2-app-a-networking.png
evidence/screenshots/aws-console/20-ec2-app-b-networking.png
```

Validated private application IPs:

```text
10.20.10.201
10.20.11.27
```

---

### Security Group Validation

The ALB security group allows public HTTP access on TCP 80.

The application security group allows inbound TCP 8080 only from the ALB security group.

Evidence:

```text
evidence/screenshots/power-shell/11-alb-security-group-cli.png
evidence/screenshots/power-shell/12-app-security-group-cli.png
evidence/screenshots/aws-console/22-alb-security-group-inbound.png
evidence/screenshots/aws-console/24-app-security-group-inbound.png
```

---

### Route Table Validation

# Secure VPC Exposure Lab

## Overview

Secure VPC Exposure Lab is an AWS networking and cloud security portfolio project built with Terraform.

The project demonstrates a secure exposure model where the only public application entry point is an internet-facing Application Load Balancer. The backend EC2 application instances run in private subnets, have no public IPv4 address, and accept application traffic only from the ALB security group.

This lab focuses on:

- AWS VPC design
- Public and private subnet segmentation
- Route table validation
- Application Load Balancer exposure
- Private EC2 application hosting
- Security group least privilege
- Custom Network ACL behavior
- VPC Flow Logs observability
- Functional exposure validation
- Terraform-based infrastructure provisioning

---

## Business Scenario

NovaRetail Cloud is a fictional B2B SaaS company that provides a private order-management application for e-commerce customers.

The company needs to expose a web application to customers through a public endpoint, but it must avoid exposing backend application servers directly to the internet.

The engineering and security requirements are:

- Customers must access the application through a public endpoint.
- Backend application servers must remain private.
- EC2 application instances must not have public IPv4 addresses.
- Application traffic to EC2 must be allowed only from the load balancer.
- SSH must not be exposed to the internet.
- Network traffic must be observable for validation and troubleshooting.
- Infrastructure must be reproducible using Infrastructure as Code.

This project implements those requirements using AWS and Terraform.

---

## Final Architecture

High-level traffic flow:

```text
Internet Client
    |
    | HTTP 80
    v
Internet Gateway
    |
    v
Public Subnets
    |
    v
Internet-facing Application Load Balancer
    |
    | HTTP 8080
    v
Private Application Subnets
    |
    v
Private EC2 Application Instances
```

The final environment includes:

- One custom VPC
- Two public subnets across two Availability Zones
- Two private application subnets across two Availability Zones
- One Internet Gateway
- Separate public and private route tables
- One internet-facing Application Load Balancer
- One HTTP listener on port 80
- One target group forwarding to TCP 8080
- Two private EC2 application instances
- Two security groups
- Two custom Network ACLs
- VPC Flow Logs delivered to CloudWatch Logs
- A minimal application deployed through EC2 user data

---

## Network Layout

### VPC

```text
VPC name: secure-vpc-exposure-lab-vpc
CIDR: 10.20.0.0/16
```

The project uses a dedicated custom VPC, not the AWS default VPC.

### Subnets

| Subnet Name | Type | CIDR | Purpose |
|---|---|---|---|
| `secure-vpc-public-a` | Public | `10.20.0.0/24` | ALB subnet in Availability Zone A |
| `secure-vpc-public-b` | Public | `10.20.1.0/24` | ALB subnet in Availability Zone B |
| `secure-vpc-private-app-a` | Private | `10.20.10.0/24` | EC2 application subnet in Availability Zone A |
| `secure-vpc-private-app-b` | Private | `10.20.11.0/24` | EC2 application subnet in Availability Zone B |

The public subnets host the Application Load Balancer.

The private application subnets host the EC2 application instances.

---

## Routing Model

### Public Route Table

The public route table contains:

```text
10.20.0.0/16 -> local
0.0.0.0/0    -> Internet Gateway
```

This allows internet-facing resources in the public subnets, such as the ALB, to communicate with internet clients.

### Private Application Route Table

The private application route table contains only:

```text
10.20.0.0/16 -> local
```

It does not contain:

```text
0.0.0.0/0 -> Internet Gateway
0.0.0.0/0 -> NAT Gateway
```

This validates that the private application subnets do not have a direct route to the internet.

---

## AWS Services Used

| Service | Purpose |
|---|---|
| Amazon VPC | Custom network boundary for the lab |
| Public Subnets | Host the public Application Load Balancer |
| Private Subnets | Host backend EC2 application instances |
| Internet Gateway | Provides internet path for public subnet resources |
| Route Tables | Separate public and private routing behavior |
| Application Load Balancer | Only public application entry point |
| Target Group | Routes ALB traffic to private EC2 instances on TCP 8080 |
| Amazon EC2 | Runs the private application instances |
| Security Groups | Enforce stateful workload-level access control |
| Network ACLs | Demonstrate subnet-level stateless filtering |
| CloudWatch Logs | Destination for VPC Flow Logs |
| VPC Flow Logs | Network metadata logging for visibility and validation |
| IAM | Dedicated role for VPC Flow Logs delivery |
| Terraform | Infrastructure as Code provisioning |

---

## Security Design

The core security principle is:

```text
The ALB is public.
The EC2 application instances are private.
```

### ALB Security Group

Security group:

```text
Name tag: sg-secure-vpc-alb
Technical group name: secure-vpc-alb
```

Inbound rule:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 80 | `0.0.0.0/0` | Allow public HTTP access to the ALB |

Outbound rule:

| Protocol | Port | Destination | Purpose |
|---|---:|---|---|
| TCP | 8080 | Application Security Group | Forward traffic to private application instances |

### Application Security Group

Security group:

```text
Name tag: sg-secure-vpc-app
Technical group name: secure-vpc-app
```

Inbound rule:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 8080 | ALB Security Group | Allow application traffic only from the ALB |

The application security group does not allow:

```text
TCP 8080 from 0.0.0.0/0
TCP 22 from 0.0.0.0/0
TCP 3389 from any public source
```

The final application security group also has no broad outbound internet rule.

---

## Network Exposure Model

| Component | Exposure | Reason |
|---|---|---|
| Application Load Balancer | Public | Only internet-facing application component |
| EC2 application instances | Private | Deployed in private subnets with no public IPv4 |
| Application port 8080 | Private behind ALB | Only reachable from the ALB security group |
| SSH | Not exposed | No inbound SSH rule exists |
| RDP | Not exposed | No inbound RDP rule exists |
| NAT Gateway | Not used | Base lab avoids NAT Gateway to reduce cost |
| VPC Flow Logs | Internal observability | Used to validate network traffic behavior |

---

## Network ACL Design

Custom Network ACLs are used to demonstrate subnet-level stateless filtering.

### Public NACL

```text
nacl-secure-vpc-public
```

Associated with:

```text
secure-vpc-public-a
secure-vpc-public-b
```

Key behavior:

- Allows inbound HTTP traffic on TCP 80 from the internet.
- Allows outbound application traffic to private application CIDR on TCP 8080.
- Allows ephemeral return traffic.
- Includes explicit deny rules.

### Private Application NACL

```text
nacl-secure-vpc-private-app
```

Associated with:

```text
secure-vpc-private-app-a
secure-vpc-private-app-b
```

Key behavior:

- Allows inbound TCP 8080 from public subnet CIDR.
- Allows outbound ephemeral return traffic to public subnet CIDR.
- Includes explicit deny rules.

Because Network ACLs are stateless, both request and response traffic must be allowed explicitly.

---

## Application Layer

The private EC2 instances run a simple HTTP application on TCP 8080.

Instances:

```text
secure-vpc-app-a
secure-vpc-app-b
```

Validated private IPs:

```text
10.20.10.201
10.20.11.27
```

Both instances have:

```text
Public IPv4 address: None
```

The application is deployed using:

```text
app/user-data.sh
```

The script starts a minimal Python HTTP server locally on the instance. It does not require external package downloads during boot.

### Application Endpoints

| Endpoint | Expected Response |
|---|---|
| `/` | `Secure VPC Exposure Lab - Private Application Instance` |
| `/health` | `OK` |

---

## Terraform Implementation

The infrastructure is deployed with Terraform.

Main Terraform files:

```text
terraform/
|-- providers.tf
|-- variables.tf
|-- locals.tf
|-- main.tf
|-- vpc.tf
|-- subnets.tf
|-- routes.tf
|-- security-groups.tf
|-- nacl.tf
|-- alb.tf
|-- ec2.tf
|-- flow-logs.tf
|-- iam.tf
`-- outputs.tf
```

The application bootstrap script is stored in:

```text
app/user-data.sh
```

The Terraform configuration creates the VPC, subnet layout, routing, security groups, NACLs, ALB, target group, EC2 instances, IAM role, CloudWatch log group, and VPC Flow Logs.

---

## Key Terraform Outputs

The project exposes these Terraform outputs:

```text
vpc_id
public_subnet_ids
private_subnet_ids
alb_dns_name
alb_security_group_id
app_security_group_id
target_group_arn
flow_logs_log_group_name
app_instance_private_ips
```

Evidence:

```text
evidence/screenshots/power-shell/01-terraform-outputs.png
```

---

## Validation Results

The environment was validated through Terraform outputs, AWS CLI commands, AWS Console screenshots, CloudWatch Logs Insights, and functional curl tests.

### Functional Application Test

Commands:

```powershell
curl.exe http://<alb_dns_name>/
curl.exe http://<alb_dns_name>/health
```

Expected output:

```text
Secure VPC Exposure Lab - Private Application Instance
OK
```

Evidence:

```text
evidence/screenshots/power-shell/17-functional-curl-tests-cli.png
```

### Target Group Health

Both EC2 application instances were registered in the target group and reported as healthy on port 8080.

Evidence:

```text
evidence/screenshots/power-shell/09-target-health-cli.png
evidence/screenshots/aws-console/17-target-group-healthy-targets.png
```

### EC2 Private Exposure Validation

The EC2 application instances were validated with private IP addresses and no public IPv4 addresses.

Evidence:

```text
evidence/screenshots/power-shell/10-ec2-private-instances-cli.png
evidence/screenshots/aws-console/19-ec2-app-a-networking.png
evidence/screenshots/aws-console/20-ec2-app-b-networking.png
```

### Security Group Validation

The ALB security group allows public HTTP access on TCP 80.

The application security group allows inbound TCP 8080 only from the ALB security group.

Evidence:

```text
evidence/screenshots/power-shell/11-alb-security-group-cli.png
evidence/screenshots/power-shell/12-app-security-group-cli.png
evidence/screenshots/aws-console/22-alb-security-group-inbound.png
evidence/screenshots/aws-console/23-alb-security-group-outbound.png
evidence/screenshots/aws-console/24-app-security-group-inbound.png
evidence/screenshots/aws-console/25-app-security-group-outbound.png
```

### Route Table Validation

The private application route table does not contain a default route to an Internet Gateway or NAT Gateway.

Evidence:

```text
evidence/screenshots/power-shell/05-private-route-table-no-default-route-cli.png
evidence/screenshots/aws-console/07-public-route-table.png
evidence/screenshots/aws-console/09-private-route-table.png
```

### Network ACL Validation

Custom NACLs were associated with the public and private application subnet tiers.

Evidence:

```text
evidence/screenshots/power-shell/13-network-acls-cli.png
evidence/screenshots/aws-console/27-public-nacl-associations.png
evidence/screenshots/aws-console/28-public-nacl-inbound-rules.png
evidence/screenshots/aws-console/29-public-nacl-outbound-rules.png
evidence/screenshots/aws-console/30-private-nacl-associations.png
evidence/screenshots/aws-console/31-private-nacl-inbound-rules.png
evidence/screenshots/aws-console/32-private-nacl-outbound-rules.png
```

---

## Logging and Observability

VPC Flow Logs are enabled at the VPC level.

Configuration:

| Setting | Value |
|---|---|
| Resource type | VPC |
| Traffic type | ALL |
| Destination | CloudWatch Logs |
| Log group | `/aws/vpc/secure-vpc-exposure-lab/flowlogs` |
| Retention | 7 days |

Evidence:

```text
evidence/screenshots/power-shell/14-vpc-flow-log-status-cli.png
evidence/screenshots/power-shell/15-cloudwatch-log-group-retention-cli.png
evidence/screenshots/power-shell/16-flow-log-streams-cli.png
evidence/screenshots/aws-console/33-vpc-flow-log-details.png
evidence/screenshots/aws-console/34-cloudwatch-log-group-retention.png
```

CloudWatch Logs Insights confirmed accepted application traffic on TCP 8080 between ALB nodes and private EC2 instances.

Evidence:

```text
evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png
```

Observed traffic pattern:

```text
10.20.0.x    -> 10.20.10.201  TCP 8080  ACCEPT OK
10.20.1.x    -> 10.20.11.27   TCP 8080  ACCEPT OK
10.20.10.201 -> 10.20.0.x     TCP 8080  ACCEPT OK
10.20.11.27  -> 10.20.1.x     TCP 8080  ACCEPT OK
```

---

## Evidence and Screenshots

Evidence is organized under:

```text
evidence/screenshots/
|-- aws-console/
`-- power-shell/
```

Important evidence includes:

| Evidence | Path |
|---|---|
| VPC details | `evidence/screenshots/aws-console/01-vpc-details.png` |
| VPC resource map | `evidence/screenshots/aws-console/02-vpc-resource-map.png` |
| Subnet overview | `evidence/screenshots/aws-console/03-subnets-overview.png` |
| ALB details | `evidence/screenshots/aws-console/11-alb-details.png` |
| ALB listener | `evidence/screenshots/aws-console/14-alb-listener-http-80.png` |
| Target group healthy targets | `evidence/screenshots/aws-console/17-target-group-healthy-targets.png` |
| EC2 private instances | `evidence/screenshots/power-shell/10-ec2-private-instances-cli.png` |
| ALB security group | `evidence/screenshots/power-shell/11-alb-security-group-cli.png` |
| App security group | `evidence/screenshots/power-shell/12-app-security-group-cli.png` |
| VPC Flow Logs status | `evidence/screenshots/power-shell/14-vpc-flow-log-status-cli.png` |
| Functional curl test | `evidence/screenshots/power-shell/17-functional-curl-tests-cli.png` |
| Logs Insights ACCEPT evidence | `evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png` |

Screenshots were redacted where needed to avoid exposing unnecessary account-level identifiers.

---

## Documentation

Additional project documentation is available in:

```text
docs/
|-- architecture.md
|-- security-design.md
|-- exposure-validation.md
|-- logging-and-observability.md
`-- troubleshooting.md
```

Supporting validation material is available in:

```text
tests/
|-- validation-commands.md
`-- expected-results.md
```

Traffic flow details are available in:

```text
architecture/
`-- traffic-flow.md
```

Cleanup instructions are available in:

```text
cleanup.md
```

---

## Lessons Learned

This project demonstrates several practical AWS security and networking lessons:

- A subnet name alone does not make a workload private.
- Private exposure must be validated with route tables, public IP assignment, and security rules.
- An ALB can be public while backend EC2 instances remain private.
- Security groups should express the intended trust boundary.
- Network ACLs require careful bidirectional rule design because they are stateless.
- VPC Flow Logs provide useful network-level evidence for traffic validation.
- Terraform state files must never be committed to a public repository.
- Temporary AWS credentials can expire during long Terraform operations and require re-authentication.

---

## Repository Structure

```text
secure-vpc-exposure-lab/
|-- README.md
|-- cleanup.md
|-- .gitignore
|-- app/
|   `-- user-data.sh
|-- architecture/
|   `-- traffic-flow.md
|-- docs/
|   |-- architecture.md
|   |-- security-design.md
|   |-- exposure-validation.md
|   |-- logging-and-observability.md
|   `-- troubleshooting.md
|-- evidence/
|   `-- screenshots/
|       |-- aws-console/
|       `-- power-shell/
|-- screenshots/
|   `-- README.md
|-- terraform/
|   |-- providers.tf
|   |-- variables.tf
|   |-- locals.tf
|   |-- main.tf
|   |-- vpc.tf
|   |-- subnets.tf
|   |-- routes.tf
|   |-- security-groups.tf
|   |-- nacl.tf
|   |-- alb.tf
|   |-- ec2.tf
|   |-- flow-logs.tf
|   |-- iam.tf
|   |-- outputs.tf
|   `-- .terraform.lock.hcl
`-- tests/
    |-- validation-commands.md
    `-- expected-results.md
```

---

## Cost Control

The base architecture intentionally avoids NAT Gateway to reduce cost.

The lab still creates billable resources, including:

- Application Load Balancer
- EC2 instances
- CloudWatch Logs storage
- VPC Flow Logs ingestion

When the lab is no longer needed, destroy the infrastructure:

```powershell
cd terraform
terraform destroy
```

See:

```text
cleanup.md
```

---

## Security and Privacy Notes

This repository does not include:

- Terraform state files
- AWS credentials
- Private keys
- Full AWS account IDs
- Full sensitive ARNs
- Secrets or tokens

Safe-to-show technical identifiers include:

- Resource names
- VPC IDs
- Subnet IDs
- Security group IDs
- Instance IDs
- Private IP addresses
- Private CIDR ranges
- ALB DNS name

Screenshots and evidence are redacted where needed before publication.

---

## Project Status

Phase 1 infrastructure and functional validation are complete.

Validated final state:

```text
Internet user
  -> Public Application Load Balancer
  -> Private EC2 application instances on TCP 8080
  -> VPC Flow Logs evidence in CloudWatch Logs
```

This confirms that the application is publicly reachable through the ALB while the EC2 application layer remains private.