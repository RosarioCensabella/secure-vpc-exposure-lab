resource "aws_security_group" "alb" {
  name        = "secure-vpc-alb"
  description = "Allow public HTTP access to the ALB and outbound application traffic to private instances."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "sg-secure-vpc-alb"
    Role = "Application Load Balancer"
  }
}

resource "aws_security_group" "app" {
  name        = "secure-vpc-app"
  description = "Allow application traffic only from the ALB security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "sg-secure-vpc-app"
    Role = "Private Application"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTP access to the internet-facing ALB."

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow ALB traffic to private application instances on TCP 8080."

  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id = aws_security_group.app.id
  description       = "Allow application traffic only from the ALB security group."

  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.alb.id
}