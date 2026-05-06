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

&#x20;   |

&#x20;   v

Internet Gateway

&#x20;   |

&#x20;   v

Public Subnets

&#x20;   |

&#x20;   v

Internet-facing Application Load Balancer

&#x20;   |

&#x20;   v

Private Application Subnets

&#x20;   |

&#x20;   v

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



The lab is designed around a simple but important exposure principle:



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



The public route table contains a default route to the Internet Gateway.



The private application route table does not contain a default route to an Internet Gateway or NAT Gateway.



Evidence:



```text

evidence/screenshots/power-shell/05-private-route-table-no-default-route-cli.png

evidence/screenshots/aws-console/07-public-route-table.png

evidence/screenshots/aws-console/09-private-route-table.png

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

```



CloudWatch Logs Insights was used to confirm accepted application traffic on TCP 8080 between ALB nodes and private EC2 instances.



Evidence:



```text

evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png

```



Example observed pattern:



```text

10.20.0.x  -> 10.20.10.201  TCP 8080  ACCEPT OK

10.20.1.x  -> 10.20.11.27   TCP 8080  ACCEPT OK

```



---



## Lessons Learned



This project demonstrates several practical cloud security lessons:



- A subnet name alone does not make a workload private; routing and public IP assignment must be validated.

- The ALB can be public while backend EC2 instances remain private.

- Security groups are the primary workload-level access control mechanism.

- Network ACLs require careful bidirectional rule design because they are stateless.

- VPC Flow Logs provide useful network-level evidence, especially when validating traffic paths.

- Terraform state must be protected and must not be committed to a public repository.

- Temporary credentials can expire during long Terraform operations and may require re-authentication before continuing.



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



Screenshots and evidence are redacted where needed before publication.



---



## Project Status



Phase 1 infrastructure and functional validation are complete.



Validated final state:



```text

Internet user

&#x20; -> Public Application Load Balancer

&#x20; -> Private EC2 application instances on TCP 8080

&#x20; -> VPC Flow Logs evidence in CloudWatch Logs

```


