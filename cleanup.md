# Cleanup Guide



## Purpose



This document explains how to safely destroy the Secure VPC Exposure Lab infrastructure when it is no longer needed.



The lab creates billable AWS resources, so cleanup is important for cost control.



---



## Cost Warning



This lab may generate costs for resources such as:



- Application Load Balancer

- EC2 instances

- CloudWatch Logs storage

- VPC Flow Logs ingestion

- VPC-related resources



The base build intentionally avoids NAT Gateway to reduce cost, but the lab should still be destroyed when not in use.



---



## Before Destroying



Before running cleanup, make sure that all portfolio evidence has already been collected.



Recommended evidence to save first:



```text

evidence/screenshots/aws-console/

evidence/screenshots/power-shell/

```



At minimum, confirm that you have saved:



```text

ALB details

Target group healthy targets

EC2 private instance validation

Security group rules

Route table validation

VPC Flow Logs ACCEPT evidence

Functional curl test

Final Terraform plan screenshot

```



Do not destroy the lab before collecting screenshots and validation evidence needed for the GitHub portfolio.



---



## Terraform Destroy



From the project root, go to the Terraform directory:



```powershell

cd terraform

```



Run:



```powershell

terraform destroy

```



Terraform will show a list of resources that will be destroyed.



When prompted:



```text

Do you really want to destroy all resources?

```



Type:



```text

yes

```



---



## Expected Result



A successful cleanup should end with:



```text

Destroy complete!

```



The exact number of destroyed resources may vary depending on the final state of the lab.



---



## Post-Cleanup Validation



After `terraform destroy`, verify that the main lab resources are gone.



### Check EC2 instances



```powershell

aws ec2 describe-instances `

&#x20; --filters "Name=tag:Project,Values=Secure VPC Exposure Lab" `

&#x20; --query "Reservations\[\*].Instances\[\*].\[Tags\[?Key=='Name']|\[0].Value,InstanceId,State.Name]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Expected result:



```text

No running lab instances.

```



Terminated instances may still appear for a short period in AWS.



---



### Check ALB



```powershell

aws elbv2 describe-load-balancers `

&#x20; --names secure-vpc-exposure-lab-alb `

&#x20; --no-cli-pager

```



Expected result:



```text

LoadBalancerNotFound

```



---



### Check VPC



```powershell

aws ec2 describe-vpcs `

&#x20; --filters "Name=tag:Name,Values=secure-vpc-exposure-lab-vpc" `

&#x20; --query "Vpcs\[\*].\[VpcId,CidrBlock,State]" `

&#x20; --output table `

&#x20; --no-cli-pager

```



Expected result:



```text

No VPC returned.

```



---



## Files Not to Delete Locally



Do not delete the project source files if this repository will be published to GitHub.



Keep:



```text

README.md

cleanup.md

.gitignore

app/

architecture/

docs/

evidence/

screenshots/

terraform/\*.tf

terraform/.terraform.lock.hcl

tests/

```



---



## Files That Should Not Be Published



These files should not be committed to GitHub:



```text

terraform/.terraform/

terraform/terraform.tfstate

terraform/terraform.tfstate.backup

\*.tfvars

\*.tfplan

credentials

.env

\*.pem

\*.key

```



The `.gitignore` file should exclude them.



---



## If Destroy Fails



If `terraform destroy` fails because AWS credentials expired, refresh credentials and retry:



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



Then retry:



```powershell

terraform destroy

```



---



## If Dependencies Block Deletion



If AWS reports dependency errors, check for:



- Load balancer still attached to subnets

- Target group attachments still present

- Network interfaces still in use

- Flow Log still attached to the VPC

- Internet Gateway still attached to the VPC



Terraform normally handles deletion order automatically, but dependency cleanup may take a few minutes.



Wait briefly and rerun:



```powershell

terraform destroy

```



---



## Summary



Use `terraform destroy` when the lab is no longer needed.



The goal is to avoid unnecessary AWS costs while keeping the GitHub repository, Terraform code, documentation, and redacted evidence available for the portfolio.


