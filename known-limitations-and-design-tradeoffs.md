# Known Limitations and Design Trade-offs

## Purpose

This document explains the intentional limitations, scope boundaries, and design trade-offs of the **Secure VPC Exposure Lab**.

The project was built as a **Phase 1 AWS networking and exposure-validation lab**. Its primary goal was to prove a specific security model:

```text
Internet users can reach the application only through the public Application Load Balancer.

The EC2 application instances remain private, have no public IPv4 address, and accept application traffic only from the ALB security group.
```

This document does not describe the Phase 1 choices as mistakes. Instead, it explains:

- what was intentionally kept simple;
- why the choice was acceptable for the Phase 1 lab;
- what risk or limitation remains;
- what would change in a production-grade version.

---

## Phase 1 Scope

Phase 1 focused on:

- building the AWS network foundation with Terraform;
- creating a custom VPC;
- separating public and private subnets;
- exposing only the Application Load Balancer publicly;
- keeping EC2 application instances private;
- preventing direct public access to EC2;
- restricting application traffic to the ALB-to-EC2 path;
- using security groups and custom Network ACLs;
- enabling VPC Flow Logs to CloudWatch Logs;
- validating the design through CLI commands, curl tests, target health checks, and Flow Logs queries.

Phase 1 intentionally did not try to become a complete production platform.

The base lab was designed to be:

- understandable;
- low cost;
- easy to reproduce;
- focused on network exposure;
- focused on validation evidence.

---

## What the Lab Proves

| Control Area | What Was Proven |
|---|---|
| Public exposure | The public entry point is the Application Load Balancer. |
| Private compute | EC2 application instances run in private subnets. |
| Public IP control | EC2 application instances have no public IPv4 address. |
| Security group control | Application instances accept TCP 8080 only from the ALB security group. |
| Routing control | Private application subnets do not have a default route to an Internet Gateway or NAT Gateway. |
| Load balancing | The ALB forwards traffic to healthy private EC2 targets. |
| Health checks | The ALB target group validates `/health` successfully. |
| Observability | VPC Flow Logs show accepted TCP 8080 traffic between ALB nodes and private EC2 instances. |
| Cost awareness | The base design avoids NAT Gateway. |

---

## What the Lab Does Not Prove

The lab does not claim to be a complete production-grade security architecture.

It does not fully implement:

- public HTTPS termination;
- HTTP-to-HTTPS redirect;
- end-to-end TLS between ALB and targets;
- AWS WAF;
- ALB access logs;
- centralized SIEM integration;
- automated CI/CD deployment;
- automated security scanning;
- Auto Scaling Groups;
- patch management through SSM;
- private VPC endpoints;
- production IAM boundary policies;
- full operating system hardening;
- application authentication or authorization;
- application-layer logging.

These are valid production improvements, but they were outside the Phase 1 scope.

---

# 1. HTTP Instead of HTTPS on the Public ALB

## Current Phase 1 Design

The Application Load Balancer uses:

```text
Listener: HTTP
Port: 80
```

The target group uses:

```text
Protocol: HTTP
Port: 8080
```

This means traffic from the client to the ALB is not encrypted in the base Phase 1 implementation.

## Why This Was Done

The goal of Phase 1 was to validate the network exposure model:

```text
Internet -> Public ALB -> Private EC2 instances
```

The project did not require a custom domain or ACM certificate to prove that model.

Using HTTP allowed the lab to stay focused on:

- public vs private subnet behavior;
- ALB forwarding;
- security group boundaries;
- target group health;
- VPC Flow Logs evidence;
- low-cost and fast validation.

## What Risk Remains

Without HTTPS, traffic between the browser/client and the ALB is not encrypted.

That is not acceptable for a real public application handling sensitive information.

## Why It Was Acceptable for Phase 1

The application is a demo app with no authentication, no user data, and no sensitive payload.

The purpose was not to protect real user data. The purpose was to prove controlled exposure of private EC2 instances through an ALB.

## Production-Grade Improvement

A production version should use:

```text
HTTP 80  -> redirect to HTTPS 443
HTTPS 443 -> forward to private targets
```

Recommended changes:

- request or import an ACM certificate;
- add an HTTPS listener on port 443;
- attach the ACM certificate to the HTTPS listener;
- use a modern ALB security policy;
- redirect HTTP port 80 to HTTPS port 443;
- optionally enable HSTS at the application or edge layer;
- optionally use HTTPS between the ALB and the targets if end-to-end encryption is required.

## Interview Explanation

```text
Phase 1 intentionally used HTTP to keep the lab focused on network exposure validation. The design proves that only the ALB is public and that EC2 remains private. In a production-grade version, I would add ACM-based TLS termination on the ALB, create a 443 listener, and redirect all port 80 traffic to HTTPS.
```

---

# 2. Application Service Runs as root

## Current Phase 1 Design

The application is started by a systemd service created by `app/user-data.sh`.

In the base lab, the service uses:

```text
User=root
```

## Why This Was Done

The user-data script was intentionally simple.

The focus of the lab was not Linux service hardening. It was:

- VPC design;
- ALB exposure;
- EC2 private placement;
- security group control;
- VPC Flow Logs validation.

Using `root` simplified the bootstrap process and avoided additional user creation logic during the first infrastructure phase.

## What Risk Remains

Running an application process as `root` increases risk.

If the application were compromised, the attacker would have higher privileges on the instance.

This is especially unnecessary because the application listens on TCP 8080, which is not a privileged port.

## Why It Was Acceptable for Phase 1

The application is a minimal demo service.

The instance is private, has no public IP, does not expose SSH, and accepts application traffic only from the ALB security group.

However, from a security-hardening perspective, running as root is still not ideal.

## Production-Grade Improvement

A hardened version should:

- create a dedicated system user, for example `securevpc`;
- run the service as that user;
- use `NoNewPrivileges=true`;
- use systemd hardening options such as `ProtectSystem`, `ProtectHome`, and `PrivateTmp`;
- restrict file permissions on the application script.

Example direction:

```text
User=securevpc
Group=securevpc
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
```

## Interview Explanation

```text
The app runs as root in Phase 1 only because the bootstrap was kept intentionally simple. Since the service listens on 8080, it does not need root privileges. In a hardened version, I would create a dedicated non-login system user and run the service with least privilege using systemd hardening options.
```

---

# 3. IMDSv2 Is Not Explicitly Enforced

## Current Phase 1 Design

The EC2 instances are created with:

```text
associate_public_ip_address = false
```

They are placed in private subnets and use the application security group.

However, the Phase 1 Terraform configuration does not explicitly configure:

```text
metadata_options {
  http_tokens = "required"
}
```

## Why This Was Done

The Phase 1 EC2 instances do not use an application IAM instance profile for business logic.

The main security focus was network exposure, not metadata hardening.

## What Risk Remains

If an EC2 instance has access to instance metadata and an application vulnerability exists, metadata access can become a risk.

IMDSv2 reduces exposure by requiring session-oriented metadata tokens.

## Why It Was Acceptable for Phase 1

The instances are private, have no public IP, and do not expose SSH.

The app is minimal and does not rely on AWS credentials.

Still, explicitly requiring IMDSv2 is a common EC2 hardening control and should be added in a stronger portfolio version.

## Production-Grade Improvement

Add metadata options to both EC2 resources:

```hcl
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"
  http_put_response_hop_limit = 1
}
```

## Interview Explanation

```text
The Phase 1 lab focused on network isolation, so IMDSv2 was not part of the initial scope. I agree it is an important EC2 hardening improvement. I would add metadata_options with http_tokens = required to enforce IMDSv2 on both private EC2 instances.
```

---

# 4. VPC Flow Logs IAM Trust Policy Can Be Hardened

## Current Phase 1 Design

The project creates an IAM role that allows VPC Flow Logs to deliver logs to CloudWatch Logs.

The trust policy allows:

```text
Service principal: vpc-flow-logs.amazonaws.com
```

## Why This Was Done

The trust policy was kept simple to support the Flow Logs delivery path required by Phase 1.

The goal was to validate that:

```text
VPC Flow Logs -> CloudWatch Logs
```

was active and usable for traffic analysis.

## What Risk Remains

A trust policy without `aws:SourceAccount` and `aws:SourceArn` conditions is broader than necessary.

In production IAM design, condition keys help reduce confused deputy risk.

## Why It Was Acceptable for Phase 1

The role was scoped to the lab and used only for VPC Flow Logs.

It was enough to support the functional observability requirement.

## Production-Grade Improvement

Use a trust policy that includes:

```text
aws:SourceAccount
aws:SourceArn
```

In Terraform, the account ID should be retrieved dynamically with:

```hcl
data "aws_caller_identity" "current" {}
```

Then use that value in the IAM trust policy conditions.

## Interview Explanation

```text
The Phase 1 trust policy was enough for Flow Logs delivery, but I would harden it in a production-grade version by adding aws:SourceAccount and aws:SourceArn conditions. That reduces confused deputy risk and makes the role trust relationship more explicit.
```

---

# 5. Manual Validation Instead of Automated Tests

## Current Phase 1 Design

The repository contains:

```text
tests/validation-commands.md
tests/expected-results.md
```

These files document manual validation commands and expected outcomes.

## Why This Was Done

Phase 1 was built interactively to validate infrastructure behavior step by step.

Manual validation was useful because the project required observing:

- Terraform outputs;
- AWS CLI results;
- ALB target health;
- EC2 public IP absence;
- security group rules;
- NACL rules;
- VPC Flow Logs results;
- functional curl responses.

## What Risk Remains

Manual tests are not automatically enforced.

A future change could break Terraform formatting, validation, or security assumptions without being caught automatically.

## Why It Was Acceptable for Phase 1

The Phase 1 goal was learning, building, and validating the architecture.

The manual tests were appropriate for proving the lab behavior during the first implementation.

## Production-Grade Improvement

Add GitHub Actions for:

- `terraform fmt -check`;
- `terraform init -backend=false`;
- `terraform validate`;
- IaC scanning with tools such as Checkov, tfsec, or Trivy config scanning.

## Interview Explanation

```text
The tests folder documents manual validation evidence, which was appropriate for the lab build. For a more mature portfolio version, I would add a GitHub Action to run terraform fmt, terraform validate, and IaC scanning on every push or pull request.
```

---

# 6. AMI Selection Uses most_recent = true

## Current Phase 1 Design

The EC2 AMI is selected with a Terraform data source using:

```text
most_recent = true
```

for Amazon Linux 2023.

## Why This Was Done

This made the lab easy to deploy without hardcoding a region-specific AMI ID.

It also allowed the instances to use a current Amazon Linux 2023 image at deployment time.

## What Risk Remains

The exact AMI can change over time.

That means a future deployment may use a different AMI than the original validated build.

This reduces strict reproducibility.

## Why It Was Acceptable for Phase 1

For a learning lab, using the latest Amazon Linux 2023 AMI is practical and reduces maintenance overhead.

The application is minimal and does not depend on a specific AMI build beyond having Python 3 and systemd available.

## Production-Grade Improvement

Expose an optional AMI variable:

```hcl
variable "ami_id" {
  description = "Optional AMI ID for EC2 application instances. If null, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = null
}
```

Then use:

```hcl
ami = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id
```

## Interview Explanation

```text
I used most_recent = true to keep the lab simple and region-friendly. For stricter reproducibility, I would expose ami_id as an optional variable or pin a tested AMI ID. That would make future deployments more deterministic.
```

---

# 7. No NAT Gateway in the Base Version

## Current Phase 1 Design

The private application route table does not include a NAT Gateway route.

The private route table contains only:

```text
10.20.0.0/16 -> local
```

## Why This Was Done

This was an intentional cost and exposure decision.

The lab requirement was:

```text
Do not create NAT Gateway in the base version.
```

Avoiding NAT Gateway also reinforces the idea that private EC2 instances should not need direct outbound internet access for this lab.

## What Risk or Limitation Remains

Without NAT Gateway or VPC endpoints, the private EC2 instances cannot directly reach public AWS APIs or internet repositories.

This impacts:

- package updates;
- external downloads;
- SSM connectivity, unless endpoints are added;
- agent-based management tools.

## Why It Was Acceptable for Phase 1

The user-data script does not need to download packages from the internet.

The app is created locally on the instance.

The lab is designed to be low-cost and focused on exposure validation.

## Production-Grade Improvement

A production version could use:

- NAT Gateway for controlled outbound internet access;
- VPC endpoints for private access to AWS services;
- SSM Session Manager with appropriate VPC endpoints;
- patch management through SSM or golden AMIs.

## Interview Explanation

```text
The lack of NAT Gateway is intentional. The lab was designed to keep costs low and to prove that the application can work without private instances needing public internet access. In production, I would evaluate NAT Gateway or VPC endpoints depending on patching, management, and egress requirements.
```

---

# 8. No Public SSH Access

## Current Phase 1 Design

No inbound SSH rule exists.

The application security group does not allow:

```text
TCP 22 from 0.0.0.0/0
```

The EC2 instances also have no public IPv4 address.

## Why This Was Done

Direct SSH exposure is not required for the lab.

The project goal is application exposure through the ALB, not administrative access from the internet.

## What Limitation Remains

Without SSH and without SSM endpoints, direct troubleshooting inside the instance is limited.

## Why It Was Acceptable for Phase 1

The app is simple and validated externally through:

- ALB target health;
- curl tests;
- EC2 state;
- security group inspection;
- VPC Flow Logs.

## Production-Grade Improvement

Use AWS Systems Manager Session Manager with private VPC endpoints instead of public SSH.

## Interview Explanation

```text
I intentionally did not expose SSH because administrative access was outside the lab objective. For production, I would prefer SSM Session Manager through VPC endpoints instead of opening SSH to the internet.
```

---

# 9. No WAF, ALB Access Logs, or Advanced Monitoring

## Current Phase 1 Design

The project includes VPC Flow Logs but does not include:

- AWS WAF;
- ALB access logs;
- CloudWatch dashboards;
- CloudWatch alarms;
- centralized SIEM export.

## Why This Was Done

The observability scope was intentionally focused on network-level validation through VPC Flow Logs.

The goal was to prove traffic behavior, not build a complete monitoring stack.

## What Risk or Limitation Remains

Without WAF and ALB access logs, the project does not provide:

- HTTP request inspection;
- Layer 7 attack filtering;
- request-level audit logs;
- rate-based rules;
- bot protection;
- application-level visibility.

## Production-Grade Improvement

A production version should consider:

- AWS WAF on the ALB;
- ALB access logs to S3;
- CloudWatch metrics and alarms;
- centralized logging;
- application logs;
- Security Hub / GuardDuty integration.

## Interview Explanation

```text
Phase 1 used VPC Flow Logs because the goal was network exposure validation. In production, I would add ALB access logs and WAF to gain HTTP-layer visibility and protection.
```

---

# 10. EC2 Instead of ECS, EKS, or Serverless

## Current Phase 1 Design

The application runs on EC2 instances.

## Why This Was Done

EC2 makes the networking model very explicit.

It helps demonstrate:

- subnet placement;
- public IP assignment;
- security group attachment;
- target group registration;
- instance-level traffic behavior;
- VPC Flow Logs on ENIs.

## What Limitation Remains

EC2 requires more operational responsibility than managed container or serverless platforms.

## Why It Was Acceptable for Phase 1

The goal was to study AWS networking and exposure control directly.

EC2 is ideal for understanding the relationship between instances, subnets, route tables, security groups, NACLs, and Flow Logs.

## Production-Grade Improvement

Depending on requirements, production could use:

- Auto Scaling Groups;
- ECS with Fargate;
- EKS;
- Lambda behind ALB or API Gateway;
- golden AMIs;
- patch management.

## Interview Explanation

```text
I chose EC2 because the project is specifically about understanding VPC exposure and private compute networking. EC2 makes subnet placement, public IP behavior, security groups, and Flow Logs very visible. In production, ECS, EKS, or serverless might be better depending on operational requirements.
```

---

# 11. Terraform Instead of Console-Only Deployment

## Current Phase 1 Design

Terraform is the primary deployment method.

AWS Console was used only for verification and troubleshooting.

## Why This Was Done

Terraform makes the infrastructure:

- repeatable;
- reviewable;
- version-controlled;
- easier to document;
- easier to destroy and recreate.

## Limitation

The project used local Terraform state during the lab workflow.

Local state is acceptable for a personal lab, but not ideal for team or production use.

## Production-Grade Improvement

Use remote state with:

- S3 backend;
- DynamoDB locking;
- state encryption;
- separate environments;
- CI-based Terraform validation.

## Interview Explanation

```text
I used Terraform because I wanted the architecture to be reproducible and reviewable. For production, I would move state to an S3 backend with DynamoDB locking and enforce Terraform checks through CI.
```

---

# Recommended Hardening Roadmap

## Quick Documentation Fixes

These do not require redeploying infrastructure:

- Add this `Known Limitations and Design Trade-offs` document.
- Add a README link to this document.
- Clarify that Phase 1 is a secure exposure lab, not a production-grade deployment.
- Document HTTPS, IMDSv2, non-root service, and IAM trust policy improvements.

## Code Hardening Improvements

Recommended next code improvements:

1. Run the app as a non-root user.
2. Enforce IMDSv2 on EC2 instances.
3. Harden the VPC Flow Logs IAM trust policy.
4. Add an optional `ami_id` variable.
5. Add GitHub Actions for Terraform validation.
6. Add a `known-limitations.md` link in the README.
7. Add HTTPS listener and HTTP-to-HTTPS redirect if a domain and ACM certificate are available.

## Production-Grade Improvements

For a real production application, consider:

- ACM certificate and HTTPS listener;
- HTTP-to-HTTPS redirect;
- AWS WAF;
- ALB access logs;
- SSM Session Manager with VPC endpoints;
- NAT Gateway or VPC endpoints for controlled outbound access;
- Auto Scaling Group or ECS/Fargate;
- CloudWatch alarms;
- centralized logging;
- GuardDuty and Security Hub;
- remote Terraform state;
- CI/CD deployment workflow;
- vulnerability scanning and patch management.

---

## Final Positioning

The correct way to position this project is:

```text
This is a Phase 1 AWS secure exposure lab. It demonstrates controlled public exposure through an ALB while keeping EC2 application instances private, without public IPs, and reachable only from the ALB security group. It also validates the design through target health checks, CLI tests, and VPC Flow Logs.

It is not presented as a complete production architecture. The known limitations are documented, and the next hardening steps are clearly identified.
```

This positioning is honest, technically accurate, and strong for a cloud/security portfolio.
