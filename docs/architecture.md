# Architecture



## Purpose



This document describes the architecture of the Secure VPC Exposure Lab.



The lab demonstrates a controlled AWS network exposure model where the public entry point is limited to an internet-facing Application Load Balancer, while the application EC2 instances run in private subnets and are not directly reachable from the internet.



---



## High-Level Architecture



```text

Internet Client

&#x20;   |

&#x20;   v

Internet Gateway

&#x20;   |

&#x20;   v

Public Subnets across two Availability Zones

&#x20;   |

&#x20;   v

Internet-facing Application Load Balancer

&#x20;   |

&#x20;   v

Private Application Subnets across two Availability Zones

&#x20;   |

&#x20;   v

Private EC2 Application Instances on TCP 8080

```



---



## Core Design Goals



The architecture was built to satisfy the following goals:



- Provide a public application endpoint.

- Keep application EC2 instances private.

- Prevent direct internet access to EC2 instances.

- Allow application traffic to EC2 only from the ALB security group.

- Use explicit routing and subnet separation.

- Demonstrate custom Network ACL behavior.

- Enable network observability through VPC Flow Logs.

- Keep the base lab small and cost-conscious.



---



## Network Layout



### VPC



The lab uses a dedicated custom VPC:



```text

VPC name: secure-vpc-exposure-lab-vpc

CIDR: 10.20.0.0/16

```



The VPC is not the default VPC. It is used only for this lab environment.



---



## Subnet Layout



The VPC contains four subnets across two Availability Zones.



| Subnet Name | Type | CIDR | Purpose |

|---|---|---|---|

| `secure-vpc-public-a` | Public | `10.20.0.0/24` | ALB subnet in Availability Zone A |

| `secure-vpc-public-b` | Public | `10.20.1.0/24` | ALB subnet in Availability Zone B |

| `secure-vpc-private-app-a` | Private | `10.20.10.0/24` | EC2 application subnet in Availability Zone A |

| `secure-vpc-private-app-b` | Private | `10.20.11.0/24` | EC2 application subnet in Availability Zone B |



The public subnets host the Application Load Balancer.



The private application subnets host the EC2 application instances.



---



## Routing Design



### Public Route Table



The public route table contains:



```text

10.20.0.0/16 -> local

0.0.0.0/0    -> Internet Gateway

```



This allows resources placed in the public subnets, such as the Application Load Balancer, to communicate with internet clients.



### Private Application Route Table



The private application route table contains only the local VPC route:



```text

10.20.0.0/16 -> local

```



It does not contain:



```text

0.0.0.0/0 -> Internet Gateway

0.0.0.0/0 -> NAT Gateway

```



This is a key part of the exposure model. The private EC2 instances do not have a direct route to or from the internet.



---



## Application Load Balancer



The Application Load Balancer is deployed in the two public subnets.



Configuration:



| Setting | Value |

|---|---|

| Name | `secure-vpc-exposure-lab-alb` |

| Scheme | `internet-facing` |

| Type | `application` |

| Listener | HTTP port 80 |

| Target group | `secure-vpc-exposure-lab-tg` |



The ALB is the only public application entry point.



---



## Target Group



The target group forwards traffic to private EC2 instances.



| Setting | Value |

|---|---|

| Name | `secure-vpc-exposure-lab-tg` |

| Protocol | HTTP |

| Port | 8080 |

| Target type | instance |

| Health check path | `/health` |

| Matcher | 200 |



The target group registers two EC2 instances, one in each private application subnet.



---



## EC2 Application Layer



The application layer consists of two EC2 instances:



```text

secure-vpc-app-a

secure-vpc-app-b

```



Both instances:



- Run in private application subnets.

- Have no public IPv4 address.

- Use the application security group.

- Listen on TCP 8080.

- Are registered in the ALB target group.

- Respond to `/` and `/health`.



The application is bootstrapped with `app/user-data.sh`, which creates a minimal local HTTP server using Python.



No external package download is required during instance boot.



---



## Traffic Flow



### Client Request Flow



```text

1\. Internet client sends an HTTP request to the ALB DNS name on port 80.

2\. The Internet Gateway routes the traffic to the public subnets.

3\. The ALB receives the request.

4\. The ALB forwards the request to a healthy EC2 target on TCP 8080.

5\. The EC2 instance returns the application response.

6\. The response is sent back through the ALB to the client.

```



### Application Endpoints



| Endpoint | Response |

|---|---|

| `/` | `Secure VPC Exposure Lab - Private Application Instance` |

| `/health` | `OK` |



---



## Security Boundaries



The architecture separates public and private responsibilities:



| Layer | Public or Private | Notes |

|---|---|---|

| Internet Gateway | Public edge | Attached to the VPC |

| Public subnets | Public tier | Used by the ALB |

| Application Load Balancer | Public | Only internet-facing application component |

| Private application subnets | Private tier | Used by EC2 application instances |

| EC2 application instances | Private | No public IPv4 address |

| VPC Flow Logs | Internal observability | Records network traffic metadata |



---



## Network ACL Placement



Custom Network ACLs are associated with both subnet tiers:



| NACL | Associated Subnets |

|---|---|

| `nacl-secure-vpc-public` | Public subnets |

| `nacl-secure-vpc-private-app` | Private application subnets |



The custom NACLs demonstrate stateless subnet-level filtering while keeping the application path functional.



---



## Observability



VPC Flow Logs are enabled at the VPC level.



Configuration:



| Setting | Value |

|---|---|

| Traffic type | ALL |

| Destination | CloudWatch Logs |

| Log group | `/aws/vpc/secure-vpc-exposure-lab/flowlogs` |

| Retention | 7 days |



Flow Logs were used to confirm accepted traffic on TCP 8080 between ALB nodes and private EC2 instances.



---



## Architecture Evidence



Relevant evidence screenshots:



```text

evidence/screenshots/aws-console/02-vpc-resource-map.png

evidence/screenshots/aws-console/03-subnets-overview.png

evidence/screenshots/aws-console/11-alb-details.png

evidence/screenshots/aws-console/17-target-group-healthy-targets.png

evidence/screenshots/power-shell/04-subnets-cli.png

evidence/screenshots/power-shell/06-alb-details-cli.png

evidence/screenshots/power-shell/09-target-health-cli.png

```



---



## Summary



This architecture proves that the application can be publicly reachable without exposing the EC2 application instances directly to the internet.



The public boundary is the Application Load Balancer.



The private compute layer remains isolated in private subnets, has no public IPv4 addresses, and receives application traffic only through the intended ALB-to-application path.


