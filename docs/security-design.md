# Security Design



## Purpose



This document explains the security design of the Secure VPC Exposure Lab.



The goal is to demonstrate a controlled AWS exposure model where only the Application Load Balancer is public, while the EC2 application instances remain private and accept application traffic only from the ALB security group.



---



## Security Objective



The main security objective is:



```text

Internet users can reach the application only through the public Application Load Balancer.

The private EC2 application instances are not directly reachable from the internet.

```



This is enforced through a combination of:



- Subnet placement

- Route table design

- Security groups

- Network ACLs

- Public IP restrictions

- VPC Flow Logs validation



---



## Public and Private Separation



The architecture separates public and private responsibilities.



| Component | Exposure | Purpose |

|---|---|---|

| Application Load Balancer | Public | Receives HTTP traffic from internet users |

| EC2 application instances | Private | Run the backend application |

| Public subnets | Public tier | Host the ALB |

| Private application subnets | Private tier | Host the EC2 application instances |



The EC2 application instances are placed only in private application subnets and do not have public IPv4 addresses.



---



## Security Groups



Security groups are the primary access control mechanism in this lab.



They are stateful and are used to enforce the intended application path:



```text

Internet

&#x20; -> ALB Security Group on TCP 80

&#x20; -> Application Security Group on TCP 8080

```



---



## ALB Security Group



Security group:



```text

Name tag: sg-secure-vpc-alb

Technical group name: secure-vpc-alb

```



### Inbound Rule



| Protocol | Port | Source | Purpose |

|---|---:|---|---|

| TCP | 80 | `0.0.0.0/0` | Allow public HTTP access to the ALB |



This is the only public inbound rule required for the application.



### Outbound Rule



| Protocol | Port | Destination | Purpose |

|---|---:|---|---|

| TCP | 8080 | Application Security Group | Forward traffic from the ALB to private application instances |



The ALB security group does not need broad outbound internet access for this lab.



---



## Application Security Group



Security group:



```text

Name tag: sg-secure-vpc-app

Technical group name: secure-vpc-app

```



### Inbound Rule



| Protocol | Port | Source | Purpose |

|---|---:|---|---|

| TCP | 8080 | ALB Security Group | Allow application traffic only from the ALB |



This rule ensures that private EC2 instances do not accept application traffic directly from the internet.



### Outbound Rules



The final application security group configuration does not include a broad outbound rule to `0.0.0.0/0`.



This supports the isolation goal of the lab and avoids unnecessary outbound exposure from the application layer.



---



## Explicitly Not Allowed



The following rules are intentionally not present:



```text

TCP 8080 from 0.0.0.0/0 to the application security group

TCP 22 from 0.0.0.0/0

TCP 3389 from public sources

Broad all-traffic outbound rule on the application security group

```



This prevents direct public access to the private EC2 application instances.



---



## Public IP Controls



The EC2 application instances were launched with:



```text

associate_public_ip_address = false

```



Validated result:



```text

secure-vpc-app-a -> Public IPv4: None

secure-vpc-app-b -> Public IPv4: None

```



This is a critical part of the exposure model.



Even if a workload is in a private subnet, the public IP assignment must still be validated.



---



## Route Table Security



### Public Route Table



The public route table allows internet connectivity for the ALB:



```text

10.20.0.0/16 -> local

0.0.0.0/0    -> Internet Gateway

```



### Private Application Route Table



The private application route table does not contain a default route:



```text

10.20.0.0/16 -> local

```



It does not include:



```text

0.0.0.0/0 -> Internet Gateway

0.0.0.0/0 -> NAT Gateway

```



This helps ensure that EC2 application instances do not have direct internet routing.



---



## Network ACL Design



Custom Network ACLs are used to demonstrate stateless subnet-level filtering.



Security groups remain the main workload-level control, while NACLs provide an additional subnet-level traffic filter.



---



## Public Subnet NACL



NACL:



```text

nacl-secure-vpc-public

```



Associated with:



```text

secure-vpc-public-a

secure-vpc-public-b

```



### Key Rules



| Direction | Rule | Protocol | Port Range | Source / Destination | Action |

|---|---:|---|---|---|---|

| Inbound | 100 | TCP | 80 | `0.0.0.0/0` | Allow |

| Inbound | 110 | TCP | 1024-65535 | `10.20.10.0/23` | Allow |

| Outbound | 100 | TCP | 8080 | `10.20.10.0/23` | Allow |

| Outbound | 110 | TCP | 1024-65535 | `0.0.0.0/0` | Allow |

| Both | 32766 | ALL | ALL | `0.0.0.0/0` | Deny |



---



## Private Application Subnet NACL



NACL:



```text

nacl-secure-vpc-private-app

```



Associated with:



```text

secure-vpc-private-app-a

secure-vpc-private-app-b

```



### Key Rules



| Direction | Rule | Protocol | Port Range | Source / Destination | Action |

|---|---:|---|---|---|---|

| Inbound | 100 | TCP | 8080 | `10.20.0.0/23` | Allow |

| Outbound | 100 | TCP | 1024-65535 | `10.20.0.0/23` | Allow |

| Both | 32766 | ALL | ALL | `0.0.0.0/0` | Deny |



Because NACLs are stateless, return traffic must be explicitly allowed.



---



## Defense-in-Depth View



This project uses multiple controls together:



| Control | Security Contribution |

|---|---|

| Private subnets | Keep EC2 instances out of the public subnet tier |

| No public IPv4 on EC2 | Prevent direct public addressing |

| Private route table | Prevent direct default route to the internet |

| ALB security group | Allows public HTTP only to the ALB |

| App security group | Allows TCP 8080 only from ALB SG |

| Custom NACLs | Demonstrate subnet-level stateless filtering |

| VPC Flow Logs | Provide network visibility and validation evidence |



---



## Validation Evidence



Relevant evidence screenshots:



```text

evidence/screenshots/power-shell/05-private-route-table-no-default-route-cli.png

evidence/screenshots/power-shell/10-ec2-private-instances-cli.png

evidence/screenshots/power-shell/11-alb-security-group-cli.png

evidence/screenshots/power-shell/12-app-security-group-cli.png

evidence/screenshots/power-shell/13-network-acls-cli.png

evidence/screenshots/aws-console/22-alb-security-group-inbound.png

evidence/screenshots/aws-console/23-alb-security-group-outbound.png

evidence/screenshots/aws-console/24-app-security-group-inbound.png

evidence/screenshots/aws-console/25-app-security-group-outbound.png

evidence/screenshots/aws-console/28-public-nacl-inbound-rules.png

evidence/screenshots/aws-console/31-private-nacl-inbound-rules.png

```



---



## Summary



The security design proves that the application is publicly reachable without making the EC2 application instances public.



The only public application entry point is the Application Load Balancer.



The application instances are private, have no public IPv4 address, and accept inbound application traffic only from the ALB security group on TCP 8080.


