# Traffic Flow



## Purpose



This document describes the network traffic flow of the Secure VPC Exposure Lab.



The goal is to show how an internet user reaches the private application instances without those instances being directly exposed to the internet.



---



## High-Level Flow



```text

Internet Client

&#x20;   |

&#x20;   | HTTP 80

&#x20;   v

Internet-facing Application Load Balancer

&#x20;   |

&#x20;   | HTTP 8080

&#x20;   v

Private EC2 Application Instances

```



---



## Detailed Request Flow



```text

1\. A user sends an HTTP request to the ALB DNS name.

2\. The request reaches the internet-facing Application Load Balancer on TCP port 80.

3\. The ALB listener forwards the request to the target group.

4\. The target group routes the request to a healthy EC2 instance.

5\. The EC2 instance receives the request on TCP port 8080.

6\. The application returns the response to the ALB.

7\. The ALB returns the response to the internet client.

```



---



## Public Entry Point



The only public application entry point is:



```text

secure-vpc-exposure-lab-alb

```



The ALB is:



```text

Scheme: internet-facing

Listener: HTTP 80

```



The ALB is deployed in the public subnets:



```text

secure-vpc-public-a

secure-vpc-public-b

```



---



## Private Application Targets



The application instances are:



```text

secure-vpc-app-a

secure-vpc-app-b

```



They run in private application subnets:



```text

secure-vpc-private-app-a

secure-vpc-private-app-b

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



---



## Port Mapping



| Segment | Protocol | Port |

|---|---|---:|

| Internet client to ALB | HTTP | 80 |

| ALB to private EC2 instances | HTTP | 8080 |

| EC2 health check endpoint | HTTP | 8080 |

| Return traffic | Ephemeral ports | 1024-65535 |



---



## Security Group Flow



```text

Internet

&#x20; -> ALB Security Group

&#x20;    Inbound TCP 80 from 0.0.0.0/0



ALB Security Group

&#x20; -> Application Security Group

&#x20;    Outbound TCP 8080



Application Security Group

&#x20; <- ALB Security Group

&#x20;    Inbound TCP 8080 only

```



The application security group does not allow public inbound application traffic.



---



## Route Table Flow



### Public Tier



The public route table includes:



```text

0.0.0.0/0 -> Internet Gateway

```



This allows the public ALB to communicate with internet clients.



### Private Tier



The private application route table includes only:



```text

10.20.0.0/16 -> local

```



It does not include a default route to:



```text

Internet Gateway

NAT Gateway

```



---



## Network ACL Flow



Because Network ACLs are stateless, both request and return traffic must be allowed.



### Public NACL



The public NACL allows:



```text

Inbound TCP 80 from internet

Outbound TCP 8080 to private application CIDR

Inbound ephemeral return traffic from private application CIDR

Outbound ephemeral response traffic to internet clients

```



### Private Application NACL



The private application NACL allows:



```text

Inbound TCP 8080 from public subnet CIDR

Outbound ephemeral return traffic to public subnet CIDR

```



---



## Observed Flow Logs



VPC Flow Logs confirmed accepted TCP 8080 traffic between ALB nodes and private EC2 instances.



Observed examples:



```text

10.20.0.x  -> 10.20.10.201  TCP 8080  ACCEPT OK

10.20.1.x  -> 10.20.11.27   TCP 8080  ACCEPT OK

```



Evidence:



```text

evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png

```



---



## Functional Validation



The application was tested through the ALB DNS name.



```powershell

curl.exe http://<alb_dns_name>/

curl.exe http://<alb_dns_name>/health

```



Expected responses:



```text

Secure VPC Exposure Lab - Private Application Instance

OK

```



Evidence:



```text

evidence/screenshots/power-shell/17-functional-curl-tests-cli.png

```



---



## Summary



The traffic flow proves that:



```text

Internet users reach the application through the ALB.

The ALB forwards traffic to private EC2 instances on TCP 8080.

The EC2 application instances are not directly exposed to the internet.

```


