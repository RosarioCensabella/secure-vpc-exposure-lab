# Validation Commands



## Purpose



This document lists the commands used to validate the Secure VPC Exposure Lab.



The commands prove that:



- Terraform manages the infrastructure.

- The ALB is the only public application entry point.

- EC2 application instances are private.

- Security groups enforce the intended traffic path.

- Network ACLs are associated and configured.

- VPC Flow Logs are active and contain accepted traffic evidence.



---



## 1. Terraform Outputs



```powershell

terraform output

```



Used to confirm the required Terraform outputs:



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



## 2. Final Terraform Plan



```powershell

terraform plan

```



Expected result:



```text

No changes. Your infrastructure matches the configuration.

```



Evidence:



```text

evidence/screenshots/power-shell/02-final-terraform-plan-clean.png

```



---



## 3. VPC Details



```powershell

aws ec2 describe-vpcs `

&#x20; --vpc-ids $(terraform output -raw vpc_id) `

&#x20; --query "Vpcs\[\*].\[Tags\[?Key=='Name']|\[0].Value,VpcId,CidrBlock,State,IsDefault]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Custom VPC

CIDR 10.20.0.0/16

IsDefault = False

```



Evidence:



```text

evidence/screenshots/power-shell/03-vpc-details-cli.png

```



---



## 4. Subnet Layout



```powershell

aws ec2 describe-subnets `

&#x20; --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" `

&#x20; --query "Subnets\[\*].\[Tags\[?Key=='Name']|\[0].Value,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch,SubnetId]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Two public subnets

Two private application subnets

Two Availability Zones

MapPublicIpOnLaunch = False

```



Evidence:



```text

evidence/screenshots/power-shell/04-subnets-cli.png

```



---



## 5. Private Route Table



```powershell

aws ec2 describe-route-tables `

&#x20; --filters "Name=association.subnet-id,Values=<private-subnet-a-id>,<private-subnet-b-id>" `

&#x20; --query "RouteTables\[\*].Routes\[\*].\[DestinationCidrBlock,GatewayId,NatGatewayId,State]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Private application subnets have only the local route.

No default route to Internet Gateway.

No default route to NAT Gateway.

```



Evidence:



```text

evidence/screenshots/power-shell/05-private-route-table-no-default-route-cli.png

```



---



## 6. ALB Details



```powershell

aws elbv2 describe-load-balancers `

&#x20; --names secure-vpc-exposure-lab-alb `

&#x20; --query "LoadBalancers\[\*].\[LoadBalancerName,Scheme,Type,State.Code,DNSName,VpcId,AvailabilityZones\[\*].SubnetId]" `

&#x20; --output json `

&#x20; --no-cli-pager

```



Validates:



```text

ALB exists

Scheme = internet-facing

Type = application

State = active

ALB is deployed in both public subnets

```



Evidence:



```text

evidence/screenshots/power-shell/06-alb-details-cli.png

```



---



## 7. ALB Listener



```powershell

$albArn = aws elbv2 describe-load-balancers `

&#x20; --names secure-vpc-exposure-lab-alb `

&#x20; --query "LoadBalancers\[0].LoadBalancerArn" `

&#x20; --output text `

&#x20; --no-cli-pager



aws elbv2 describe-listeners `

&#x20; --load-balancer-arn $albArn `

&#x20; --query "Listeners\[\*].\[Protocol,Port,DefaultActions\[0].Type]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Listener protocol = HTTP

Listener port = 80

Action = forward

```



Evidence:



```text

evidence/screenshots/power-shell/07-alb-listener-http-80-cli.png

```



---



## 8. Target Group Configuration



```powershell

aws elbv2 describe-target-groups `

&#x20; --names secure-vpc-exposure-lab-tg `

&#x20; --query "TargetGroups\[\*].\[TargetGroupName,Protocol,Port,TargetType,VpcId,HealthCheckProtocol,HealthCheckPath,Matcher.HttpCode]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Target group protocol = HTTP

Target group port = 8080

Target type = instance

Health check path = /health

Matcher = 200

```



Evidence:



```text

evidence/screenshots/power-shell/08-target-group-config-cli.png

```



---



## 9. Target Health



```powershell

aws elbv2 describe-target-health `

&#x20; --target-group-arn $(terraform output -raw target_group_arn) `

&#x20; --query "TargetHealthDescriptions\[\*].\[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Both EC2 targets are registered.

Both EC2 targets are healthy.

Targets use port 8080.

```



Evidence:



```text

evidence/screenshots/power-shell/09-target-health-cli.png

```



---



## 10. EC2 Private Instance Validation



```powershell

aws ec2 describe-instances `

&#x20; --filters "Name=tag:Project,Values=Secure VPC Exposure Lab" "Name=tag:Role,Values=Private Application Instance" `

&#x20; --query "Reservations\[\*].Instances\[\*].\[Tags\[?Key=='Name']|\[0].Value,InstanceId,PrivateIpAddress,PublicIpAddress,SubnetId,State.Name]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Two EC2 application instances exist.

Both instances are running.

Both instances have private IP addresses.

PublicIpAddress = None.

Both instances are in private application subnets.

```



Evidence:



```text

evidence/screenshots/power-shell/10-ec2-private-instances-cli.png

```



---



## 11. ALB Security Group



```powershell

aws ec2 describe-security-groups `

&#x20; --group-ids $(terraform output -raw alb_security_group_id) `

&#x20; --query "SecurityGroups\[0].\[GroupName,Tags\[?Key=='Name']|\[0].Value,IpPermissions,IpPermissionsEgress]" `

&#x20; --output json `

&#x20; --no-cli-pager

```



Validates:



```text

Inbound TCP 80 from 0.0.0.0/0

Outbound TCP 8080 to the application security group

```



Evidence:



```text

evidence/screenshots/power-shell/11-alb-security-group-cli.png

```



---



## 12. Application Security Group



```powershell

aws ec2 describe-security-groups `

&#x20; --group-ids $(terraform output -raw app_security_group_id) `

&#x20; --query "SecurityGroups\[0].\[GroupName,Tags\[?Key=='Name']|\[0].Value,IpPermissions,IpPermissionsEgress]" `

&#x20; --output json `

&#x20; --no-cli-pager

```



Validates:



```text

Inbound TCP 8080 only from the ALB security group

No inbound SSH

No inbound RDP

No inbound TCP 8080 from 0.0.0.0/0

No broad outbound internet rule

```



Evidence:



```text

evidence/screenshots/power-shell/12-app-security-group-cli.png

```



---



## 13. Network ACLs



```powershell

aws ec2 describe-network-acls `

&#x20; --filters "Name=tag:Name,Values=nacl-secure-vpc-public,nacl-secure-vpc-private-app" `

&#x20; --query "NetworkAcls\[\*].{Name:Tags\[?Key=='Name']|\[0].Value,SubnetIds:Associations\[\*].SubnetId,Entries:Entries\[\*].\[RuleNumber,Egress,Protocol,PortRange.From,PortRange.To,CidrBlock,RuleAction]}" `

&#x20; --output json `

&#x20; --no-cli-pager

```



Validates:



```text

Custom public NACL exists.

Custom private application NACL exists.

NACLs are associated with the correct subnets.

Rules allow the intended application path.

Explicit deny rules are present.

```



Evidence:



```text

evidence/screenshots/power-shell/13-network-acls-cli.png

```



---



## 14. VPC Flow Log Status



```powershell

aws ec2 describe-flow-logs `

&#x20; --filter "Name=resource-id,Values=$(terraform output -raw vpc_id)" `

&#x20; --query "FlowLogs\[\*].\[FlowLogId,ResourceId,TrafficType,LogDestinationType,FlowLogStatus,LogGroupName]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

VPC Flow Logs are enabled.

TrafficType = ALL.

Destination = CloudWatch Logs.

Status = ACTIVE.

```



Evidence:



```text

evidence/screenshots/power-shell/14-vpc-flow-log-status-cli.png

```



---



## 15. CloudWatch Log Group Retention



```powershell

aws logs describe-log-groups `

&#x20; --log-group-name-prefix "/aws/vpc/secure-vpc-exposure-lab/flowlogs" `

&#x20; --query "logGroups\[\*].\[logGroupName,retentionInDays]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Flow Logs log group exists.

Retention is set to 7 days.

```



Evidence:



```text

evidence/screenshots/power-shell/15-cloudwatch-log-group-retention-cli.png

```



---



## 16. Flow Log Streams



```powershell

aws logs describe-log-streams `

&#x20; --log-group-name $(terraform output -raw flow_logs_log_group_name) `

&#x20; --order-by LastEventTime `

&#x20; --descending `

&#x20; --max-items 5 `

&#x20; --query "logStreams\[\*].\[logStreamName,lastEventTimestamp]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Validates:



```text

Flow Log streams exist.

CloudWatch Logs is receiving VPC Flow Log events.

```



Evidence:



```text

evidence/screenshots/power-shell/16-flow-log-streams-cli.png

```



---



## 17. Functional Application Test



```powershell

curl.exe http://$(terraform output -raw alb_dns_name)/

curl.exe http://$(terraform output -raw alb_dns_name)/health

```



Validates:



```text

The application is reachable through the ALB.

The / endpoint returns the expected lab response.

The /health endpoint returns OK.

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



---



## 18. CloudWatch Logs Insights Query



CloudWatch Logs Insights query used to confirm accepted TCP 8080 traffic:



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



Validates:



```text

Accepted TCP 8080 traffic exists between ALB nodes and private EC2 application instances.

```



Evidence:



```text

evidence/screenshots/aws-console/36-cloudwatch-logs-insights-accept.png

```



---



## Notes



Before publishing screenshots or output:



- Redact full AWS account IDs.

- Redact full sensitive ARNs.

- Do not include credentials, tokens, or keys.

- Resource names, private IPs, VPC IDs, subnet IDs, security group IDs, and instance IDs can remain visible as technical evidence.


