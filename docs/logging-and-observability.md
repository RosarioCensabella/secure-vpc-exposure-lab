# Logging and Observability



## Purpose



This document describes the logging and observability layer of the Secure VPC Exposure Lab.



The goal is to show how VPC Flow Logs can be used as network-level evidence to validate traffic paths between the public Application Load Balancer and the private EC2 application instances.



---



## Observability Goal



The lab uses VPC Flow Logs to confirm that network traffic is being recorded for the VPC.



The main validation goal is:



```text

Show accepted TCP 8080 traffic between ALB nodes and private EC2 application instances.

```



This provides evidence that the application path is working as designed:



```text

Internet user

&#x20; -> Application Load Balancer

&#x20; -> Private EC2 application instances on TCP 8080

```



---



## VPC Flow Logs Configuration



VPC Flow Logs are enabled at the VPC level.



| Setting | Value |

|---|---|

| Resource type | VPC |

| Traffic type | ALL |

| Destination | CloudWatch Logs |

| Log group | `/aws/vpc/secure-vpc-exposure-lab/flowlogs` |

| Retention | 7 days |

| IAM role | Dedicated VPC Flow Logs delivery role |



Traffic type is set to `ALL`, which allows the lab to capture both accepted and rejected network flows.



---



## CloudWatch Log Group



The Flow Logs destination is:



```text

/aws/vpc/secure-vpc-exposure-lab/flowlogs

```



The log group retention period is configured to 7 days.



This keeps the lab cost-conscious while still allowing enough time to review validation evidence.



Evidence:



```text

evidence/screenshots/power-shell/15-cloudwatch-log-group-retention-cli.png

evidence/screenshots/aws-console/34-cloudwatch-log-group-retention.png

```



---



## Flow Log Status



The Flow Log was validated as active.



Expected configuration:



```text

TrafficType: ALL

LogDestinationType: cloud-watch-logs

FlowLogStatus: ACTIVE

LogGroupName: /aws/vpc/secure-vpc-exposure-lab/flowlogs

```



Evidence:



```text

evidence/screenshots/power-shell/14-vpc-flow-log-status-cli.png

evidence/screenshots/aws-console/33-vpc-flow-log-details.png

```



---



## Log Streams



CloudWatch Logs created log streams for network interfaces in the VPC.



Observed pattern:



```text

eni-...-all

```



These log streams confirm that Flow Logs are being delivered to CloudWatch Logs.



Evidence:



```text

evidence/screenshots/power-shell/16-flow-log-streams-cli.png


```



---



## Logs Insights Query



CloudWatch Logs Insights was used to search for accepted application traffic.



Example query:



```sql

parse @message "\* \* \* \* \* \* \* \* \* \* \* \* \* \*" as version, accountId, interfaceId, srcAddr, dstAddr, srcPort, dstPort, protocol, packets, bytes, startTime, endTime, action, logStatus

| filter action = "ACCEPT"

| filter protocol = "6"

| filter dstPort = "8080" or srcPort = "8080"

| filter srcAddr = "10.20.10.201" or srcAddr = "10.20.11.27" or dstAddr = "10.20.10.201" or dstAddr = "10.20.11.27"

| display @timestamp, interfaceId, srcAddr, dstAddr, srcPort, dstPort, protocol, action, logStatus

| sort @timestamp desc

| limit 20

```



The query filters for:



- `ACCEPT` records.

- TCP protocol, represented as protocol `6`.

- Port `8080`.

- Private EC2 application IPs.



---



## Accepted Traffic Evidence



The Flow Logs showed accepted traffic between ALB nodes and the private EC2 application instances.



Observed private application IPs:



```text

10.20.10.201

10.20.11.27

```



Observed traffic pattern:



```text

10.20.0.x    -> 10.20.10.201  TCP 8080  ACCEPT OK

10.20.1.x    -> 10.20.11.27   TCP 8080  ACCEPT OK

10.20.10.201 -> 10.20.0.x     TCP 8080  ACCEPT OK

10.20.11.27  -> 10.20.1.x     TCP 8080  ACCEPT OK

```



This confirms that traffic between the ALB layer and the private EC2 application layer is visible in VPC Flow Logs.



Evidence:



```text

evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png


```



---



## What VPC Flow Logs Prove



VPC Flow Logs help prove:



- Traffic reached network interfaces in the VPC.

- The ALB-to-application path generated accepted TCP 8080 flows.

- The private EC2 application instances participated in application traffic.

- Network-level metadata can be used to validate the exposure model.



---



## What VPC Flow Logs Do Not Prove



VPC Flow Logs are network metadata logs. They do not show:



- HTTP request paths such as `/` or `/health`.

- HTTP response bodies.

- Application logs.

- User identity at the application layer.

- Full packet payloads.



Application behavior was validated separately with `curl`.



Evidence:



```text

evidence/screenshots/power-shell/17-functional-curl-tests-cli.png

```



---



## Logging Design Notes



The lab intentionally uses CloudWatch Logs as the Flow Logs destination because it provides:



- Fast validation during a hands-on lab.

- Logs Insights query support.

- Simple evidence collection for a portfolio project.

- Short retention for cost control.



The lab does not use S3, Athena, or external analytics tools in this phase.



---



## Troubleshooting Value



VPC Flow Logs are useful when troubleshooting:



- Target group health issues.

- Missing security group rules.

- Network ACL drops.

- Incorrect routing.

- Unexpected rejected traffic.



For example:



- `ACCEPT` records on TCP 8080 help confirm that ALB-to-EC2 traffic is allowed.

- `REJECT` records can help identify blocked flows caused by NACLs or security group misconfiguration.



---



## Summary



The logging and observability layer confirms that the lab is not only functionally reachable through the ALB, but also observable at the VPC network level.



The VPC Flow Logs evidence supports the final exposure statement:



```text

The application is reached through the public ALB, and accepted TCP 8080 traffic to private EC2 instances is visible in CloudWatch Logs.

```



