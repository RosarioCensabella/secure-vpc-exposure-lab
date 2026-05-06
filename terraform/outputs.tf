output "vpc_id" {
  description = "ID of the Secure VPC Exposure Lab VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets used by the Application Load Balancer."
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private application subnets used by EC2 instances."
  value = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the private application security group."
  value       = aws_security_group.app.id
}

output "flow_logs_log_group_name" {
  description = "CloudWatch Logs log group name used by VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}

output "app_instance_private_ips" {
  description = "Private IPv4 addresses of the application EC2 instances."
  value = [
    aws_instance.app_a.private_ip,
    aws_instance.app_b.private_ip
  ]
}