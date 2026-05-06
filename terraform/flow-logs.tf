resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/secure-vpc-exposure-lab/flowlogs"
  retention_in_days = 7

  tags = {
    Name = "/aws/vpc/secure-vpc-exposure-lab/flowlogs"
    Role = "VPC Flow Logs"
  }
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  tags = {
    Name = "${local.name_prefix}-vpc-flow-log"
  }
}