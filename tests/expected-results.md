# Expected Results



## Purpose



This document summarizes the expected validation results for the Secure VPC Exposure Lab.



It is used together with:



```text

tests/validation-commands.md

```



The goal is to make the validation process easy to review without exposing sensitive AWS account details.



---



## 1. Terraform Outputs



Expected outputs:



```text

alb_dns_name

alb_security_group_id

app_instance_private_ips

app_security_group_id

flow_logs_log_group_name

private_subnet_ids

public_subnet_ids

target_group_arn

vpc_id

```



Expected notes:



```text

All required outputs are present.

Sensitive values such as full ARNs should be redacted before publication.

```



---



## 2. Final Terraform Plan



Expected result:



```text

No changes. Your infrastructure matches the configuration.

```



This confirms that the deployed AWS infrastructure matches the Terraform configuration.



---



## 3. VPC Details



Expected result:



```text

Name: secure-vpc-exposure-lab-vpc

CIDR: 10.20.0.0/16

State: available

IsDefault: False

```



This confirms that the lab uses a dedicated custom VPC.



---



## 4. Subnet Layout



Expected subnets:



| Subnet Name | CIDR | Type | Expected Public IPv4 Auto-Assign |

|---|---|---|---|

| `secure-vpc-public-a` | `10.20.0.0/24` | Public | False |

| `secure-vpc-public-b` | `10.20.1.0/24` | Public | False |

| `secure-vpc-private-app-a` | `10.20.10.0/24` | Private application | False |

| `secure-vpc-private-app-b` | `10.20.11.0/24` | Private application | False |



Expected notes:



```text

Subnets are distributed across two Availability Zones.

Application EC2 instances are placed only in private application subnets.

```



---



## 5. Route Tables



### Public Route Table



Expected routes:



```text

10.20.0.0/16 -> local

0.0.0.0/0    -> Internet Gateway

```



Expected associations:



```text

secure-vpc-public-a

secure-vpc-public-b

```



### Private Application Route Table



Expected routes:



```text

10.20.0.0/16 -> local

```



Expected not present:



```text

0.0.0.0/0 -> Internet Gateway

0.0.0.0/0 -> NAT Gateway

```



Expected associations:



```text

secure-vpc-private-app-a

secure-vpc-private-app-b

```



---



## 6. Application Load Balancer



Expected result:



```text

Name: secure-vpc-exposure-lab-alb

Scheme: internet-facing

Type: application

State: active

Listener: HTTP 80

```



Expected notes:



```text

The ALB is deployed in both public subnets.

The ALB is the only public application entry point.

```



---



## 7. Target Group



Expected result:



```text

Name: secure-vpc-exposure-lab-tg

Protocol: HTTP

Port: 8080

Target type: instance

Health check protocol: HTTP

Health check path: /health

Matcher: 200

```



---



## 8. Target Health



Expected result:



```text

Two targets are registered.

Both targets use port 8080.

Both targets are healthy.

```



Example:



```text

i-... | 8080 | healthy | None | None

i-... | 8080 | healthy | None | None

```



---



## 9. EC2 Application Instances



Expected result:



| Instance Name | Private IP | Public IPv4 | State |

|---|---|---|---|

| `secure-vpc-app-a` | `10.20.10.x` | None | running |

| `secure-vpc-app-b` | `10.20.11.x` | None | running |



Validated private IPs for this build:



```text

10.20.10.201

10.20.11.27

```



Expected notes:



```text

Both instances must have PublicIpAddress = None.

Both instances must be in private application subnets.

No key pair is required for normal validation.

```



---



## 10. ALB Security Group



Expected inbound rule:



| Protocol | Port | Source |

|---|---:|---|

| TCP | 80 | `0.0.0.0/0` |



Expected outbound rule:



| Protocol | Port | Destination |

|---|---:|---|

| TCP | 8080 | Application Security Group |



Expected notes:



```text

The ALB security group allows public HTTP access.

The ALB security group forwards only application traffic to the application security group.

```



---



## 11. Application Security Group



Expected inbound rule:



| Protocol | Port | Source |

|---|---:|---|

| TCP | 8080 | ALB Security Group |



Expected outbound rule state:



```text

No broad outbound internet rule.

```



Expected not present:



```text

TCP 8080 from 0.0.0.0/0

TCP 22 from 0.0.0.0/0

TCP 3389 from any public source

```



---



## 12. Network ACLs



### Public NACL



Expected association:



```text

secure-vpc-public-a

secure-vpc-public-b

```



Expected key rules:



| Direction | Protocol | Port Range | Source / Destination | Action |

|---|---|---|---|---|

| Inbound | TCP | 80 | `0.0.0.0/0` | Allow |

| Inbound | TCP | 1024-65535 | `10.20.10.0/23` | Allow |

| Outbound | TCP | 8080 | `10.20.10.0/23` | Allow |

| Outbound | TCP | 1024-65535 | `0.0.0.0/0` | Allow |

| Both | ALL | ALL | `0.0.0.0/0` | Deny |



### Private Application NACL



Expected association:



```text

secure-vpc-private-app-a

secure-vpc-private-app-b

```



Expected key rules:



| Direction | Protocol | Port Range | Source / Destination | Action |

|---|---|---|---|---|

| Inbound | TCP | 8080 | `10.20.0.0/23` | Allow |

| Outbound | TCP | 1024-65535 | `10.20.0.0/23` | Allow |

| Both | ALL | ALL | `0.0.0.0/0` | Deny |



Expected notes:



```text

AWS may also show the default final deny rule.

This is expected.

```



---



## 13. Functional Application Test



Expected commands:



```powershell

curl.exe http://<alb_dns_name>/

curl.exe http://<alb_dns_name>/health

```



Expected output:



```text

Secure VPC Exposure Lab - Private Application Instance

OK

```



Expected notes:



```text

The public client reaches the application through the ALB DNS name.

The client does not connect directly to the EC2 private IPs.

```



---



## 14. VPC Flow Logs



Expected Flow Log configuration:



```text

Resource type: VPC

Traffic type: ALL

Destination: CloudWatch Logs

Status: ACTIVE

Log group: /aws/vpc/secure-vpc-exposure-lab/flowlogs

Retention: 7 days

```



Expected log stream pattern:



```text

eni-...-all

```



---



## 15. CloudWatch Logs Insights ACCEPT Query



Expected result:



```text

At least one ACCEPT OK record exists for TCP 8080 traffic involving the private application IPs.

```



Expected observed pattern:



```text

10.20.0.x    -> 10.20.10.201  TCP 8080  ACCEPT OK

10.20.1.x    -> 10.20.11.27   TCP 8080  ACCEPT OK

10.20.10.201 -> 10.20.0.x     TCP 8080  ACCEPT OK

10.20.11.27  -> 10.20.1.x     TCP 8080  ACCEPT OK

```



Expected notes:



```text

This proves that VPC Flow Logs captured accepted application traffic between ALB nodes and private EC2 instances.

```



---



## 16. Final Exposure Result



Expected final statement:



```text

Internet users can reach the application only through the public Application Load Balancer.



The EC2 application instances are private, have no public IPv4 address, and accept inbound application traffic only from the ALB security group on TCP 8080.



VPC Flow Logs provide network-level evidence of accepted traffic between the ALB layer and the private application layer.

```



---



## Publication Notes



Before publishing evidence:



```text

Redact full AWS account IDs.

Redact full sensitive ARNs.

Do not publish credentials, tokens, keys, or Terraform state files.

```



Safe to show:



```text

Resource names

VPC IDs

Subnet IDs

Security group IDs

Instance IDs

Private IP addresses

ALB DNS name

Private CIDR ranges

```


