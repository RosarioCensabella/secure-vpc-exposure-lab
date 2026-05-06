# Troubleshooting



## Purpose



This document captures troubleshooting steps and lessons learned from building the Secure VPC Exposure Lab.



The goal is to document practical issues that can appear when deploying and validating AWS networking infrastructure with Terraform.



---



## Troubleshooting Order



When the application is not reachable through the ALB, troubleshoot in this order:



```text

1\. Terraform outputs

2\. ALB listener

3\. Target group health

4\. EC2 instance state

5\. EC2 user data and application process

6\. Application security group inbound rule

7\. ALB security group outbound rule

8\. Public route table and Internet Gateway route

9\. Private route table and absence of default route

10\. Network ACL rules and ephemeral return traffic

11\. VPC Flow Logs ACCEPT or REJECT records

```



This order helps avoid changing security rules randomly before confirming the actual failure point.



---



## Issue: Expired AWS Credentials



### Symptom



Terraform or AWS CLI returned an error similar to:



```text

ExpiredToken: The security token included in the request is expired

```



or:



```text

Credentials were refreshed, but the refreshed credentials are still expired.

```



### Cause



The lab used temporary AWS credentials. During long Terraform operations or validation sessions, those credentials expired.



### Fix



Refresh the AWS login and export credentials again:



```powershell

Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue

Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue

Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

Remove-Item Env:AWS_SECURITY_TOKEN -ErrorAction SilentlyContinue



aws login

aws configure export-credentials --format powershell | Invoke-Expression

$env:AWS_REGION="eu-west-1"

$env:AWS_DEFAULT_REGION="eu-west-1"

$env:AWS_EC2_METADATA_DISABLED="true"

$env:AWS_PAGER=""

```



Then validate the identity:



```powershell

aws sts get-caller-identity

```



### Lesson Learned



Temporary credentials should be refreshed before long Terraform operations or before collecting evidence.



---



## Issue: Terraform Could Not Find AWS Credentials



### Symptom



Terraform returned:



```text

No valid credential sources found

```



or attempted to use EC2 instance metadata:



```text

no EC2 IMDS role found

```



### Cause



Terraform could not access valid AWS credentials from the local environment.



### Fix



Export AWS credentials into the PowerShell session:



```powershell

aws configure export-credentials --format powershell | Invoke-Expression

$env:AWS_REGION="eu-west-1"

$env:AWS_DEFAULT_REGION="eu-west-1"

$env:AWS_EC2_METADATA_DISABLED="true"

```



### Lesson Learned



AWS CLI authentication and Terraform provider authentication must both be working before running `terraform plan` or `terraform apply`.



---



## Issue: Security Group Name Could Not Start With `sg-`



### Symptom



Terraform validation returned:



```text

invalid value for name (cannot begin with sg-)

```



### Cause



AWS rejected the technical security group name because it started with `sg-`.



### Fix



Use a compliant technical group name, while keeping the requested portfolio-facing name in the `Name` tag.



Example:



```hcl

resource "aws_security_group" "alb" {

&#x20; name = "secure-vpc-alb"



&#x20; tags = {

&#x20;   Name = "sg-secure-vpc-alb"

&#x20; }

}

```



### Lesson Learned



The AWS resource technical name and the AWS `Name` tag can be different. The `Name` tag is usually what appears most clearly in the AWS Console.



---



## Issue: ALB Creation Was Interrupted by Expired Credentials



### Symptom



Terraform created part of the ALB resources but failed while waiting for the ALB to finish provisioning:



```text

Error: waiting for ELBv2 Load Balancer create

ExpiredToken

```



A later `terraform plan` showed:



```text

aws_lb.app is tainted, so must be replaced

```



### Cause



The AWS token expired during ALB creation. Terraform marked the ALB resource as tainted even though the ALB existed in AWS.



### Fix



After refreshing credentials, inspect Terraform state:



```powershell

terraform state list

```



If the ALB already exists in state and AWS, remove the taint:



```powershell

terraform untaint aws_lb.app

```



Then run:



```powershell

terraform plan

```



Expected clean recovery:



```text

Plan: 1 to add, 0 to change, 0 to destroy.

```



In this lab, the missing resource was the HTTP listener.



### Lesson Learned



Do not immediately apply a replacement plan after a partial failure. First inspect Terraform state and AWS resources to avoid unnecessary destruction and recreation.



---



## Issue: AWS CLI Pager Blocking Output



### Symptom



AWS CLI output stopped with:



```text

-- More --

```



### Cause



AWS CLI used a pager for long output.



### Fix



Disable the pager for the session:



```powershell

$env:AWS_PAGER=""

```



or add:



```powershell

--no-cli-pager

```



to commands.



### Lesson Learned



Disable the AWS CLI pager before collecting screenshot evidence.



---



## Issue: PowerShell Table Output Failed for Nested AWS CLI Results



### Symptom



AWS CLI returned:



```text

Row should have 1 elements, instead it has 2

```



### Cause



The AWS CLI `--output table` format could not render nested list results.



### Fix



Use JSON output instead:



```powershell

aws ec2 describe-network-acls `

&#x20; --filters "Name=association.subnet-id,Values=<subnet-id-1>,<subnet-id-2>" `

&#x20; --query "NetworkAcls\[\*].{Name:Tags\[?Key=='Name']|\[0].Value,SubnetIds:Associations\[\*].SubnetId}" `

&#x20; --output json `

&#x20; --no-cli-pager

```



### Lesson Learned



Use `--output json` for nested AWS CLI query results.



---



## Issue: Target Group Not Healthy



### Symptom



Target group health check showed:



```text

initial

unhealthy

```



### Troubleshooting Steps



Check the following:



1\. EC2 instances are running.

2\. EC2 instances are registered in the target group.

3\. Target group port is `8080`.

4\. Health check path is `/health`.

5\. Application security group allows TCP 8080 from the ALB security group.

6\. ALB security group allows outbound TCP 8080 to the application security group.

7\. Private NACL allows inbound TCP 8080 from public subnet CIDR.

8\. Private NACL allows outbound ephemeral return traffic to public subnet CIDR.

9\. User data created and started the local HTTP service.

10\. VPC Flow Logs show ACCEPT or REJECT records.



Expected healthy state:



```text

i-... | 8080 | healthy | None | None

```



### Lesson Learned



Target health depends on application readiness, security groups, NACLs, and routing. Troubleshoot in layers.



---



## Issue: ALB Does Not Return Application Response



### Symptom



`curl` to the ALB DNS name does not return:



```text

Secure VPC Exposure Lab - Private Application Instance

```



or `/health` does not return:



```text

OK

```



### Troubleshooting Steps



Check:



1\. ALB is active.

2\. Listener exists on HTTP port 80.

3\. Listener forwards to the correct target group.

4\. Target group has healthy targets.

5\. EC2 user data started the application.

6\. Security groups allow the ALB-to-app path.

7\. NACLs allow both request and response traffic.

8\. Route tables are correct.



### Lesson Learned



If the target group is unhealthy, fix target health before troubleshooting client-side curl output.



---



## Issue: No VPC Flow Log Results



### Symptom



CloudWatch Logs Insights does not show recent `ACCEPT` records.



### Troubleshooting Steps



1\. Confirm the Flow Log status is `ACTIVE`.

2\. Confirm the log group exists.

3\. Confirm retention is configured.

4\. Generate fresh traffic:



```powershell

curl.exe http://<alb_dns_name>/

curl.exe http://<alb_dns_name>/health

```



5\. Set the Logs Insights time range to the last 30 or 60 minutes.

6\. Query for `ACCEPT` and port `8080`.



Example query:



```sql

fields @timestamp, @message

| filter @message like /ACCEPT/

| filter @message like / 8080 /

| sort @timestamp desc

| limit 20

```



### Lesson Learned



Flow Logs may not appear instantly. Generate fresh traffic and use an appropriate time range.



---



## Issue: Screenshots Contain Sensitive Identifiers



### Symptom



Screenshots show:



```text

AWS account ID

Full ARNs

Usernames or emails

```



### Fix



Redact before publishing to GitHub.



Safe to keep visible:



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



Redact or avoid publishing:



```text

Full AWS account ID

Full sensitive ARNs

Emails or usernames

Credentials

Access keys

Session tokens

```



### Lesson Learned



Portfolio evidence should prove the technical design without exposing unnecessary account-level identifiers.



---



## Final Lessons Learned



Key takeaways from the build:



- Terraform-first workflows make the environment reproducible.

- Private subnet placement must be validated with route tables and public IP checks.

- The ALB can be public while EC2 instances remain private.

- Security groups should express the intended trust boundary.

- NACLs require bidirectional thinking because they are stateless.

- VPC Flow Logs provide strong network evidence for exposure validation.

- Temporary AWS credentials can interrupt long operations.

- Terraform state files must never be committed to a public repository.


