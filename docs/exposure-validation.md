# Exposure Validation



## Purpose



This document explains how the Secure VPC Exposure Lab was validated.



The goal of the validation is to prove that:



```text

Internet users can reach the application only through the public Application Load Balancer.

The EC2 application instances are private and are not directly exposed to the internet.

```



---



## Validation Summary



| Validation Area | Result |

|---|---|

| ALB is internet-facing | Passed |

| ALB listener is HTTP on port 80 | Passed |

| Target group forwards to TCP 8080 | Passed |

| Both EC2 targets are healthy | Passed |

| Application `/` endpoint works through ALB | Passed |

| Application `/health` endpoint works through ALB | Passed |

| EC2 instances have no public IPv4 address | Passed |

| EC2 instances are in private subnets | Passed |

| App security group allows TCP 8080 only from ALB SG | Passed |

| No SSH exposure | Passed |

| No RDP exposure | Passed |

| VPC Flow Logs show accepted traffic | Passed |



---



## Terraform Outputs



Terraform exposed the required infrastructure outputs.



Relevant outputs include:



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



## ALB Public Access Test



The public ALB DNS name was tested with `curl`.



Commands:



```powershell

curl.exe http://<alb_dns_name>/

curl.exe http://<alb_dns_name>/health

```



Expected results:



```text

Secure VPC Exposure Lab - Private Application Instance

OK

```



Validated result:



```text

The application responded successfully through the ALB.

```



Evidence:



```text

evidence/screenshots/power-shell/17-functional-curl-tests-cli.png

```



---



## Target Group Health Validation



The target group was checked to confirm that both private EC2 instances were registered and healthy.



Command:



```powershell

aws elbv2 describe-target-health `

&#x20; --target-group-arn <target_group_arn> `

&#x20; --query "TargetHealthDescriptions\[\*].\[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]" `

&#x20; --output table

```



Expected result:



```text

Two targets on port 8080 with state healthy.

```



Validated result:



```text

Both application instances were healthy in the target group.

```



Evidence:



```text

evidence/screenshots/power-shell/09-target-health-cli.png

evidence/screenshots/aws-console/17-target-group-healthy-targets.png

```



---



## Private EC2 Exposure Validation



The EC2 instances were checked to confirm that they do not have public IPv4 addresses.



Command:



```powershell

aws ec2 describe-instances `

&#x20; --filters "Name=tag:Project,Values=Secure VPC Exposure Lab" "Name=tag:Role,Values=Private Application Instance" `

&#x20; --query "Reservations\[\*].Instances\[\*].\[Tags\[?Key=='Name']|\[0].Value,InstanceId,PrivateIpAddress,PublicIpAddress,SubnetId,State.Name]" `

&#x20; --output table

```



Validated result:



```text

secure-vpc-app-a | 10.20.10.201 | PublicIpAddress: None

secure-vpc-app-b | 10.20.11.27  | PublicIpAddress: None

```



This confirms that the EC2 application instances are not directly addressable from the public internet.



Evidence:



```text

evidence/screenshots/power-shell/10-ec2-private-instances-cli.png

evidence/screenshots/aws-console/19-ec2-app-a-networking.png

evidence/screenshots/aws-console/20-ec2-app-b-networking.png```



---



## Route Table Validation



The private application route table was checked to confirm that it does not contain a default route to an Internet Gateway or NAT Gateway.



Expected private route table:



```text

10.20.0.0/16 -> local

```



Not present:



```text

0.0.0.0/0 -> Internet Gateway

0.0.0.0/0 -> NAT Gateway

```



Evidence:



```text

evidence/screenshots/power-shell/05-private-route-table-no-default-route-cli.png

evidence/screenshots/aws-console/09-private-route-table.png

```



This supports the private exposure model by confirming that the private application subnets do not have a direct internet route.



---



## Security Group Validation



### ALB Security Group



The ALB security group was validated to allow public HTTP access:



```text

Inbound TCP 80 from 0.0.0.0/0

```



It also allows outbound application traffic:



```text

Outbound TCP 8080 to the application security group

```



Evidence:



```text

evidence/screenshots/power-shell/11-alb-security-group-cli.png

evidence/screenshots/aws-console/22-alb-security-group-inbound.png

evidence/screenshots/aws-console/23-alb-security-group-outbound.png

```



---



### Application Security Group



The application security group was validated to allow inbound application traffic only from the ALB security group:



```text

Inbound TCP 8080 from ALB Security Group

```



The application security group does not allow:



```text

TCP 8080 from 0.0.0.0/0

TCP 22 from 0.0.0.0/0

TCP 3389 from public sources

```



Validated outbound state:



```text

No broad outbound internet rule on the application security group.

```



Evidence:



```text

evidence/screenshots/power-shell/12-app-security-group-cli.png

evidence/screenshots/aws-console/24-app-security-group-inbound.png

evidence/screenshots/aws-console/25-app-security-group-outbound.png

```



---



## Network ACL Validation



Custom Network ACLs were validated for both subnet tiers.



### Public NACL



The public NACL allows:



```text

Inbound TCP 80 from 0.0.0.0/0

Outbound TCP 8080 to private application CIDR

Ephemeral return traffic

Explicit deny rules

```



### Private Application NACL



The private application NACL allows:



```text

Inbound TCP 8080 from public subnet CIDR

Outbound ephemeral return traffic to public subnet CIDR

Explicit deny rules

```



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



## Flow Logs Validation



VPC Flow Logs were used as network evidence.



The log group contains records showing accepted TCP 8080 traffic between ALB nodes and the private EC2 application instances.



Observed pattern:



```text

10.20.0.x  -> 10.20.10.201  TCP 8080  ACCEPT OK

10.20.1.x  -> 10.20.11.27   TCP 8080  ACCEPT OK

10.20.10.201 -> 10.20.0.x   TCP 8080  ACCEPT OK

10.20.11.27  -> 10.20.1.x   TCP 8080  ACCEPT OK

```



Evidence:



```text

evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png

evidence/screenshots/power-shell/16-flow-log-streams-cli.png

```



---



## Final Exposure Statement



The validated final exposure model is:



```text

Internet

&#x20; -> Public Application Load Balancer on TCP 80

&#x20; -> Private EC2 application instances on TCP 8080

```



The EC2 application instances:



- Are in private subnets.

- Have no public IPv4 address.

- Are not reachable directly from the internet.

- Accept application traffic only from the ALB security group.

- Are observable through VPC Flow Logs.



---



## Conclusion



The exposure validation confirms that the lab meets its intended security goal:



```text

The only public entry point into the application environment is the Application Load Balancer.

The EC2 application instances remain private and are not directly exposed to the internet.

```


